#' @api
NULL

#' Convert from Rd to Markdown in roxygen2 comments
#'
#' Performs various substitutions in all `.R` files in a package.
#' Also attempts to enable Markdown support in `roxygen2` by adding a field to
#' `DESCRIPTION`.
#' Carefully examine the results after running this function!
#'
#' @param pkg Path to a (subdirectory of an) R package
#' @return List of changed files, invisibly
#'
#' @export
roxygen2md <- function(pkg = ".") {
  pkg_root <- rprojroot::find_package_root_file(path = pkg)
  withr::with_dir(pkg_root, roxygen2md_local())
}

roxygen2md_local <- function() {
  files <- dir(path = "R", pattern = "[.][rR]$", recursive = TRUE, full.names = TRUE)
  add_roxygen_field()
  transform_files(files)
}

add_roxygen_field <- function() {
  if (!is_roxygen_field_markdown()) {
    roxygen_field <- desc::desc_get("Roxygen")
    roxygen_field_new <- "list(markdown = TRUE)"
    if (is.na(roxygen_field)) {
      desc::desc_set("Roxygen" = roxygen_field_new)
    } else {
      message(
        "If necessary, please update the Roxygen field in DESCRIPTION to include ",
        roxygen_field_new, "\nCurrent value: ", roxygen_field)
    }
  }
  invisible()
}

is_roxygen_field_markdown <- function() {
  roxygen_field <- desc::desc_get("Roxygen")
  if (is.na(roxygen_field)) return(FALSE)
  roxygen_field_new <- "list(markdown = TRUE)"
  if (identical(unname(roxygen_field), roxygen_field_new)) return(TRUE)

  roxygen_field_val <- try_eval_text(roxygen_field)
  isTRUE(roxygen_field_val$markdown)
}

try_eval_text <- function(text) {
  tryCatch(
    eval(parse(text = text)),
    error = function(e) NULL
  )
}

convert_local_links <- function(text) {
  rex::re_substitutes(
    global = TRUE,
    text,
    rex::rex(
      "\\code{\\link{",
      capture(one_or_more(none_of("}["))),
      "}",
      maybe("()"),
      "}"
    ),
    "[\\1()]")
}

convert_alien_links <- function(text) {
  rex::re_substitutes(
    global = TRUE,
    text,
    rex::rex(
      "\\code{\\link[",
      capture(one_or_more(none_of("]["))),
      "]{",
      capture(one_or_more(none_of("}["))),
      "}",
      maybe("()"),
      "}"
    ),
    "[\\1::\\2()]")
}

convert_S4_code_links <- function(text) {
  rex::re_substitutes(
    global = TRUE,
    text,
    rex::rex(
      "\\code{\\linkS4class{",
      capture(one_or_more(none_of("}"))),
      "}}"
    ),
    "[\\1-class]")
}

convert_S4_links <- function(text) {
  rex::re_substitutes(
    global = TRUE,
    text,
    rex::rex(
      "\\linkS4class{",
      capture(one_or_more(none_of("}"))),
      "}"
    ),
    "[\\1-class]")
}

convert_code <- function(text) {
  rex::re_substitutes(
    global = TRUE,
    text,
    rex::rex(
      "\\code{",
      capture(one_or_more(none_of("{}"))),
      "}"
    ),
    "`\\1`")
}

convert_emph <- function(text) {
  rex::re_substitutes(
    global = TRUE,
    text,
    rex::rex(
      "\\emph{",
      capture(one_or_more(none_of("{}"))),
      "}"
    ),
    "*\\1*")
}

convert_bold <- function(text) {
  rex::re_substitutes(
    global = TRUE,
    text,
    rex::rex(
      "\\bold{",
      capture(one_or_more(none_of("{}"))),
      "}"
    ),
    "**\\1**")
}

convert_url <- function(text) {
  rex::re_substitutes(
    global = TRUE,
    text,
    rex::rex(
      "\\url{",
      capture(one_or_more(none_of("{}"))),
      "}"
    ),
    "<\\1>")
}
