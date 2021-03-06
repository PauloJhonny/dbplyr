#' Cache and retrieve an `src_sqlite` of the Lahman baseball database.
#'
#' This creates an interesting database using data from the Lahman baseball
#' data source, provided by Sean Lahman at
#' \url{http://www.seanlahman.com/baseball-archive/statistics/}, and
#' made easily available in R through the \pkg{Lahman} package by
#' Michael Friendly, Dennis Murphy and Martin Monkman. See the documentation
#' for that package for documentation of the individual tables.
#'
#' @param ... Other arguments passed to `src` on first
#'   load. For MySQL and PostgreSQL, the defaults assume you have a local
#'   server with `lahman` database already created.
#'   For `lahman_srcs()`, character vector of names giving srcs to generate.
#' @param quiet if `TRUE`, suppress messages about databases failing to
#'   connect.
#' @param type src type.
#' @keywords internal
#' @examples
#' # Connect to a local sqlite database, if already created
#' \donttest{
#' if (has_lahman("sqlite")) {
#'   lahman_sqlite()
#'   batting <- tbl(lahman_sqlite(), "Batting")
#'   batting
#' }
#'
#' # Connect to a local postgres database with lahman database, if available
#' if (has_lahman("postgres")) {
#'   lahman_postgres()
#'   batting <- tbl(lahman_postgres(), "Batting")
#' }
#' }
#' @name lahman
NULL

#' @export
#' @rdname lahman
lahman_sqlite <- function(path = NULL) {
  path <- db_location(path, "lahman.sqlite")
  copy_lahman(src_sqlite(path = path, create = TRUE))
}

#' @export
#' @rdname lahman
lahman_postgres <- function(dbname = "lahman", host = "localhost", ...) {
  src <- src_postgres(dbname, host = host, ...)
  copy_lahman(src)
}

#' @export
#' @rdname lahman
lahman_mysql <- function(dbname = "lahman", ...) {
  src <- src_mysql(dbname, ...)
  copy_lahman(src)
}

#' @export
#' @rdname lahman
lahman_df <- function() {
  src_df("Lahman")
}

#' @rdname lahman
#' @export
copy_lahman <- function(src, ...) {
  # Create missing tables
  tables <- setdiff(lahman_tables(), src_tbls(src))
  for (table in tables) {
    df <- getExportedValue("Lahman", table)
    message("Creating table: ", table)

    ids <- as.list(names(df)[grepl("ID$", names(df))])
    copy_to(src, df, table, indexes = ids, temporary = FALSE)
  }

  src
}
# Get list of all non-label data frames in package
lahman_tables <- function() {
  tables <- utils::data(package = "Lahman")$results[, 3]
  tables[!grepl("Labels", tables)]
}

#' @rdname lahman
#' @export
has_lahman <- function(type, ...) {
  if (!requireNamespace("Lahman", quietly = TRUE)) return(FALSE)
  if (missing(type)) return(TRUE)

  succeeds(lahman(type, ...), quiet = FALSE)
}

#' @rdname lahman
#' @export
lahman_srcs <- function(..., quiet = NULL) {
  load_srcs(lahman, c(...), quiet = quiet)
}

lahman <- function(type, ...) {
  if (missing(type)) {
    src_df("Lahman")
  } else {
    f <- match.fun(paste0("lahman_", type))
    f(...)
  }
}
