test_that("reliab dispatches Cohen's kappa for 2 nominal raters", {
  ratings <- data.frame(
    a = c("x", "y", "x", "y", "x"),
    b = c("x", "y", "x", "y", "y")
  )
  r <- reliab(ratings, method = "cohen")
  expect_equal(r$method, "cohen")
  expect_true(r$value > 0 && r$value < 1)
  expect_equal(r$n_raters, 2)
  expect_equal(r$n_items, 5)
})

test_that("reliab auto-selects Fleiss for >2 nominal raters", {
  ratings <- data.frame(
    a = c("x", "y", "x"),
    b = c("x", "y", "x"),
    c = c("x", "x", "x")
  )
  r <- reliab(ratings, method = "auto", level = "nominal")
  expect_equal(r$method, "fleiss")
})

test_that("reliab_pairs returns one row per pair", {
  ratings <- data.frame(
    a = c("x", "y", "x", "y"),
    b = c("x", "y", "x", "y"),
    c = c("y", "y", "x", "y")
  )
  out <- reliab_pairs(ratings, method = "cohen")
  expect_equal(nrow(out), 3)
  expect_setequal(c("a", "b", "c"), unique(c(out$RaterA, out$RaterB)))
})

test_that("valid returns expected metric names", {
  gold <- c("sup", "opp", "non", "sup", "opp", "non")
  pred <- c("sup", "opp", "non", "opp", "opp", "non")
  v <- valid(gold = gold, pred = pred)
  expect_true(all(c("precision", "recall", "f1_macro", "f1_weighted",
                    "accuracy", "balanced_accuracy", "mcc") %in% names(v)))
  expect_equal(v$accuracy, 5/6)
})

test_that("valid lets user pick a subset of metrics", {
  gold <- c("sup", "opp", "non", "sup")
  pred <- c("sup", "opp", "non", "opp")
  v <- valid(gold, pred, metrics = c("f1_macro", "f1_weighted"))
  expect_named(v, c("f1_macro", "f1_weighted"))
})

test_that("dual returns reliability and validity components", {
  ratings <- data.frame(
    human = c("x", "y", "x", "y"),
    gpt   = c("x", "y", "x", "x")
  )
  out <- dual(ratings = ratings,
              gold = ratings$human,
              pred = ratings$gpt,
              reliability_method = "cohen")
  expect_named(out, c("reliability", "validity", "pred_name"))
  expect_type(out$pred_name, "character")
})

test_that("dual accepts a named list of preds (multi-annotator)", {
  ratings <- data.frame(
    human = c("x", "y", "x", "y", "x"),
    gpt   = c("x", "y", "x", "x", "x"),
    gem   = c("x", "y", "x", "y", "x")
  )
  out <- dual(
    ratings = ratings,
    gold = ratings$human,
    pred = list("GPT" = ratings$gpt, "Gem" = ratings$gem),
    reliability_method = "fleiss"
  )
  expect_true("annotator" %in% names(out$validity))
  expect_equal(nrow(out$validity), 2)
  expect_setequal(out$validity$annotator, c("GPT", "Gem"))
  expect_equal(out$pred_name, c("GPT", "Gem"))
})

test_that("dual rejects an unnamed list of preds", {
  ratings <- data.frame(
    human = c("x", "y", "x"),
    gpt   = c("x", "y", "x")
  )
  expect_error(
    dual(ratings = ratings, gold = ratings$human,
         pred = list(ratings$gpt, ratings$gpt),
         reliability_method = "fleiss"),
    "named list"
  )
})

test_that("role suggests metric families", {
  rt <- role("annotator", "classify stance",
             gold = TRUE, prompt_type = "few-shot")
  expect_s3_class(rt, "craft_role")
  expect_true("kripp" %in% rt$suggested_metrics$reliability)
  expect_true("f1_macro" %in% rt$suggested_metrics$validity)
})

test_that("audit categorizes correctly", {
  ann <- data.frame(
    id = 1:4,
    label_a = c("sup", "sup", "sup", "opp"),
    label_b = c("sup", "sup", "opp", "opp"),
    confidence_a = c(0.9, 0.4, 0.8, 0.2),
    confidence_b = c(0.9, 0.5, 0.7, 0.2)
  )
  out <- audit(ann, confidence_threshold = 0.6, low_threshold = 0.31)
  expect_equal(out$audit_status,
               c("agreement", "low_conf_agreement",
                 "disagreement", "uncertainty_agreement"))
})

test_that("stab returns one row per variant", {
  out <- stab(
    list("GPT-5" = c("sup","opp","non","sup","opp","non"),
         "Gemi"  = c("sup","opp","non","opp","opp","non")),
    gold = c("sup","opp","non","sup","opp","non"),
    reliability_method = "cohen"
  )
  expect_equal(nrow(out), 2)
  expect_true("variant" %in% names(out))
})
