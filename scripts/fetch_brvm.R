suppressPackageStartupMessages({
  library(BRVM)
  library(jsonlite)
  library(dplyr)
})

message("Fetching BRVM market data...")
raw_data <- tryCatch(BRVM_get("all"), error = function(e) {
  stop("BRVM_get failed: ", conditionMessage(e))
})

if (is.null(raw_data) || !is.data.frame(raw_data) || nrow(raw_data) == 0) {
  stop("BRVM returned an empty or invalid dataset.")
}

names(raw_data) <- tolower(trimws(names(raw_data)))
ticker_col <- intersect(c("ticker", "symbol", "symbole", "code"), names(raw_data))[1]
price_col  <- intersect(c("close", "price", "cours", "dernier", "dernier cours"), names(raw_data))[1]
change_col <- grep("change|var", names(raw_data), value = TRUE)[1]

if (is.na(ticker_col) || is.na(price_col)) {
  stop("Required ticker/price columns not found. Columns: ", paste(names(raw_data), collapse = ", "))
}

# Parse numeric values safely. BRVM package values are usually numeric;
# this also supports decimal commas when values are strings.
parse_number <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  x <- trimws(as.character(x))
  x[x == ""] <- NA_character_
  x <- gsub("\\s", "", x)
  # A comma without a dot is treated as a decimal separator.
  comma_decimal <- grepl(",", x, fixed = TRUE) & !grepl(".", x, fixed = TRUE)
  x[comma_decimal] <- gsub(",", ".", x[comma_decimal], fixed = TRUE)
  x[!comma_decimal] <- gsub(",", "", x[!comma_decimal], fixed = TRUE)
  suppressWarnings(as.numeric(x))
}

clean_df <- raw_data %>%
  transmute(
    ticker = toupper(trimws(as.character(.data[[ticker_col]]))),
    price = parse_number(.data[[price_col]]),
    change = if (!is.na(change_col)) parse_number(.data[[change_col]]) else NA_real_
  ) %>%
  filter(
    !is.na(ticker), grepl("^[A-Z0-9]{3,8}$", ticker),
    is.finite(price), price > 0
  ) %>%
  distinct(ticker, .keep_all = TRUE)

if (nrow(clean_df) < 30) {
  stop("Too few valid tickers (", nrow(clean_df), "). Refusing to publish.")
}

quotes_map <- as.list(setNames(clean_df$price, clean_df$ticker))
changes_map <- as.list(setNames(ifelse(is.finite(clean_df$change), clean_df$change, 0), clean_df$ticker))

payload <- list(
  source = "BRVM R package",
  isSeed = FALSE,
  currency = "XOF",
  updatedAt = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  count = nrow(clean_df),
  quotes = quotes_map,
  dailyChangePct = changes_map
)

write_json(payload, "quotes.json", auto_unbox = TRUE, pretty = TRUE, na = "null")
message("quotes.json updated: ", nrow(clean_df), " tickers.")
