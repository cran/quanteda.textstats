library("quanteda")

test_that("textstat_lexdiv computation is correct", {
    mydfm <- dfm(tokens(c(d1 = "b a b a b a b a",
                             d2 = "a a b b")))
    expect_equivalent(
        textstat_lexdiv(mydfm, "TTR"),
        data.frame(document = c("d1", "d2"), TTR = c(0.25, 0.5),
                   stringsAsFactors = FALSE)
        )
})

test_that("textstat_lexdiv CTTR works correctly", {
    mydfm <- dfm(tokens(c(d1 = "b a b a b a b a",
                             d2 = "a a b b")))
    expect_equivalent(
        textstat_lexdiv(mydfm, "CTTR")$CTTR,
        c(2 / sqrt(2 * 8), 2 / sqrt(2 * 4)),
        tolerance = 0.01
    )
})

test_that("textstat_lexdiv R works correctly", {
    mydfm <- dfm(tokens(c(d1 = "b a b a b a b a",
                             d2 = "a a b b")))
    expect_equivalent(
        textstat_lexdiv(mydfm, "R")$R,
        c(2 / sqrt(8), 2 / sqrt(4)),
        tolerance = 0.01
    )
})

test_that("textstat_lexdiv C works correctly", {
    mydfm <- dfm(tokens(c(d1 = "b a b a b a b a",
                             d2 = "a a b b")))
    expect_equivalent(
        textstat_lexdiv(mydfm, "C")$C,
        c(log10(2) / log10(8), log10(2) / log10(4)),
        tolerance = 0.01
    )
})

test_that("textstat_lexdiv Maas works correctly", {
    mydfm <- dfm(tokens(c(d1 = "b a b a b a b a",
                   d2 = "a a b b")))
    expect_equivalent(
        textstat_lexdiv(mydfm, "Maas")$Maas[1],
        sqrt((log10(8) - log10(2)) / log10(8) ^ 2),
        tolerance = 0.01
    )
})

test_that("textstat_lexdiv Yule's I works correctly", {
    mydfm <- dfm(tokens(c(d1 = "a b c",
                   d2 = "a a b b c")))
    expect_equivalent(
        textstat_lexdiv(mydfm, "I")$I[1], 0, tolerance = 0.01
    )
    expect_equivalent(
        textstat_lexdiv(mydfm, "I")$I[2], (3^2) / ((1 + 2 * 2^2) - 3), tolerance = 0.01
    )
})

test_that("textstat_lexdiv works with a single document dfm (#706)", {
    mytxt <- "one one two one one two one"
    mydfm <- dfm(tokens(mytxt))
    expect_equivalent(
        textstat_lexdiv(mydfm, c("TTR", "C")),
        data.frame(document = "text1", TTR = 0.286, C = 0.356,
                   stringsAsFactors = FALSE),
        tolerance = 0.01
    )
})

test_that("raises error when dfm is empty (#1419)", {
    mx <- dfm_trim(data_dfm_lbgexample, 1000)
    expect_error(textstat_lexdiv(mx, c("TTR", "C")),
                 quanteda.textstats:::message_error("dfm_empty"))
})

test_that("Yule's K and Herndon's Vm correction are (approximately) correct", {
    # read in Latin version of Ch 1 of the Gospel according to St. John
    # example from Table 1 of Miranda-Garcia, A, and J Calle-Martin. 2005.
    # “Yule's Characteristic K Revisited.” Language Resources and Evaluation
    # 39(4): 287–94.
    # text source: http://www.latinvulgate.com/verse.aspx?t=1&b=4&c=1
    df <- read.csv("../data/stjohn_latin.csv", stringsAsFactors = FALSE)
    data_corpus_stjohn <- df %>%
        corpus(text_field = "latin") %>%
        corpus_group(groups = df$chapter) # %>%
        # as.character() %>%  # combine verses into a single document
        # corpus(docvars = data.frame(chapter = 1:4))
    docnames(data_corpus_stjohn) <- paste0("chap", 1:4)

    data_dfm_stjohn <- data_corpus_stjohn %>%
        tokens(remove_punct = TRUE) %>%
        tokens_tolower() %>%
        dfm()

    # work with chapter 1
    data_dfm_stjohnch1 <- dfm_subset(data_dfm_stjohn, chapter == 1)

    freqs <- data_dfm_stjohnch1 %>%
        featfreq() %>%
        head(n = 331) %>%
        sort(decreasing = FALSE)
    freqnames <- names(freqs)
    # from Table 1
    freqs <- c(rep(1, 212),
           rep(2, 51),
           rep(3, 26),
           rep(4, 13),
           rep(5, 6),
           rep(6, 6),
           rep(7, 3),
           rep(8, 4),
           rep(10, 1),
           rep(11, 1),
           rep(13, 3),
           rep(16, 1),
           rep(17, 1),
           rep(19, 1),
           rep(21, 1),
           rep(59, 1))
    names(freqs) <- freqnames
    dfmat <- as.dfm(matrix(freqs, nrow = 1, dimnames = list(docnames(data_dfm_stjohnch1),
                                                            freqnames)))
    expect_identical(
        as.integer(ntoken(dfmat)), # 770
        755L     # from Miranda-Garcia and Calle-Martin (2005, Table 1)
    )

    expect_identical(
        as.integer(ntype(dfmat)),  # 329
        331L     # from Miranda-Garcia and Calle-Martin (2005, Table 1)
    )

    expect_equivalent(
        textstat_lexdiv(dfmat, "K"),  # 112.767
        # from Miranda-Garcia and Calle-Martin (2005, Table 3)
        data.frame(document = "chap1", K = 113.091583, stringsAsFactors = FALSE),
        tolerance = 0.5
    )

    # tests on multiple documents - this is Ch 1 and Chs 1-4 as per the first two rows of
    # Table 3 of Miranda-Garcia and Calle-Martin (2005)
    data_dfm_stjohncomb <- rbind(data_dfm_stjohnch1,
                                 dfm_group(data_dfm_stjohn, rep(1, 4)))
    docnames(data_dfm_stjohncomb)[2] <- "chaps1-4"
    expect_equivalent(
        textstat_lexdiv(data_dfm_stjohncomb, "K"),
        data.frame(document = c("chap1", "chaps1-4"), K = c(113.091583, 109.957455),
                   stringsAsFactors = FALSE),
        tolerance = 1
    )

    # try also Herdan's Vm and Simpson's D - these are VERY WEAK tests
    expect_true(
        all(textstat_lexdiv(data_dfm_stjohncomb, "D")[1, "D", drop = TRUE] > 0)
    )
    expect_true(
        all(textstat_lexdiv(data_dfm_stjohncomb, "Vm")[1, "Vm", drop = TRUE] > 0)
    )

    # test equality as per Tweedie and Baayen (1998, Eq. 19)
    # this needs checking - the tol value is a fudge
    result <- textstat_lexdiv(data_dfm_stjohncomb, c("K", "Vm"))
    K <- result[["K"]]
    Vm <- result[["Vm"]]
    expect_equal(
        Vm ^ 2,
        as.numeric(K / 10 ^ 4 + (1 / ntoken(data_dfm_stjohncomb) - 1 /
                                     ntype(data_dfm_stjohncomb))),
        tol = .0013
    )
})

# Tests for multiple static measures of lexical diversity
static_measures <- c("TTR", "C", "R", "CTTR", "U", "S", "K", "D", "Vm", "Maas")

test_that("textstat_lexdiv works similarly for corpus and tokens", {
    txt <- c(d1 = "b a b a b a b a",
             d2 = "a a b b")
    mydfm <- dfm(tokens(txt))
    mytokens <- tokens(txt)
    expect_identical(
        textstat_lexdiv(mydfm, measure = static_measures),
        textstat_lexdiv(mytokens, measure = static_measures)
    )
})

test_that("textstat_lexdiv supports removal of punctuation, numbers and symbols", {
    txt <- c(d1 = "a a  b b  c c",
             d2 = "a a , b b . c c / & ^ *** ### 1 2 3 4")
    mt <- dfm(tokens(txt))
    toks <- tokens(txt)
    expect_identical(
        textstat_lexdiv(mt["d1", ], measure = static_measures)[, -1],
        textstat_lexdiv(mt["d2", ], measure = static_measures)[, -1]
    )
    expect_identical(
        textstat_lexdiv(toks["d1"], measure = static_measures)[, -1],
        textstat_lexdiv(toks["d2"], measure = static_measures)[, -1]
    )
})

test_that("textstat_lexdiv supports removal of hyphenation", {
    y <- dfm(tokens(c(d1 = "apple-pear orange-fruit elephant-ferrari",
               d2 = "alpha-beta charlie-delta echo-foxtrot")))
    z <- dfm(tokens(c(d1 = "apple pear orange fruit elephant ferrari",
               d2 = "alpha beta charlie delta echo foxtrot")))
    expect_identical(
        textstat_lexdiv(y, measure = static_measures, remove_hyphens = TRUE),
        textstat_lexdiv(z, measure = static_measures, remove_hyphens = TRUE)
    )
})

test_that("textstat_lexdiv can handle hyphenated words containing duplicated tokens ", {
    dfm_nested <- dfm(tokens(corpus(c(d1 = "have we not-we-have bicycle ! % 123 ^ "))))
    # not-we-have should be separated into three tokens, with hyphens being removed
    # remaining punctuation, symbols and numbers should also be removed
    # dfm_nested should only have 4 types with 6 tokens
    dfm_non_nested <- dfm(tokens(corpus(c(d1 = "a b b c c d"))))
    expect_identical(textstat_lexdiv(dfm_nested, measure = static_measures, remove_hyphens = TRUE),
                     textstat_lexdiv(dfm_non_nested, measure = static_measures))
})

test_that("textstat_lexdiv.dfm and .tokens work same with remove_* options", {
    txt <- c("There's shrimp-kabobs,
              shrimp creole, shrimp gumbo. Pan fried, deep fried, stir-fried. There's
              pineapple shrimp, lemon shrimp, coconut shrimp, pepper shrimp, shrimp soup,
              shrimp stew, shrimp salad, shrimp and potatoes, shrimp burger, shrimp
              sandwich.",
             "A shrimp-kabob costs $0.50, shrimp costs $0.25.")
    expect_identical(
        textstat_lexdiv(tokens(txt), measure = "TTR", remove_hyphens = TRUE),
        textstat_lexdiv(dfm(tokens(txt), tolower = FALSE), measure = "TTR", remove_hyphens = TRUE)
    )
    expect_identical(
        textstat_lexdiv(tokens(txt), measure = "TTR",
                        remove_punct = TRUE, remove_hyphens = TRUE),
        textstat_lexdiv(dfm(tokens(txt)), measure = "TTR",
                        remove_punct = TRUE, remove_hyphens = TRUE)
    )
    expect_identical(
        textstat_lexdiv(tokens(txt), measure = "TTR", remove_punct = TRUE),
        textstat_lexdiv(dfm(tokens(txt)), measure = "TTR", remove_punct = TRUE)
    )
    expect_identical(
        textstat_lexdiv(tokens(txt[2]), measure = "TTR", remove_symbols = TRUE),
        textstat_lexdiv(dfm(tokens(txt[2])), measure = "TTR", remove_symbols = TRUE)
    )
    expect_true(
        textstat_lexdiv(dfm(tokens(txt[2])), measure = "TTR", remove_symbols = TRUE)[1, "TTR"] !=
        textstat_lexdiv(dfm(tokens(txt[2])), measure = "TTR", remove_symbols = FALSE)[1, "TTR"]
    )
    expect_identical(
        textstat_lexdiv(tokens(txt), measure = "TTR", remove_numbers = TRUE),
        textstat_lexdiv(dfm(tokens(txt)), measure = "TTR", remove_numbers = TRUE)
    )
})


test_that("textstat_lexdiv does not support dfm for MATTR and MSTTR", {
    mytxt <- "one one two one one two one"
    mydfm <- dfm(tokens(mytxt))
    expect_error(
        textstat_lexdiv(mydfm, measure = "MATTR"),
        "average-based measures are only available for tokens inputs"
    )
    expect_error(
        textstat_lexdiv(mydfm, measure = "MSTTR"),
        "average-based measures are only available for tokens inputs"
    )
})

test_that("textstat_lexdiv.tokens raises errors if parameters for moving measures are not specified", {
    # skip("defaults may have changed")
    mytxt <- "one one two one one two one"
    mytoken <- tokens(mytxt)

    expect_warning(
        textstat_lexdiv(mytoken, measure = "MATTR", MATTR_window = 100),
        "MATTR_window exceeds some documents' token lengths, resetting to 7"
    )
    # expect_error(
    #     textstat_lexdiv(mytoken, measure = "MSTTR"),
    #     "MSTTR_segment_size must be specified if MSTTR is to be computed"
    # )
})

test_that("textstat_lexdiv.tokens MATTR works correctly on its own", {
    mytxt <- "one one two one one two one"
    mytoken <- tokens(mytxt)
    wsize2_MATTR <- (1/2 + 1 + 1 + 1/2 + 1 + 1) / 6
    wsize3_MATTR <- (2/3 + 2/3 + 2/3 + 2/3 + 2/3) / 5
    wsize4_MATTR <- (2/4 + 2/4 + 2/4 + 2/4) / 4

    expect_identical(
        textstat_lexdiv(mytoken, measure = "MATTR", MATTR_window = 2)[["MATTR"]],
        wsize2_MATTR
    )
    expect_identical(
        textstat_lexdiv(mytoken, measure = "MATTR", MATTR_window = 3)[["MATTR"]],
        wsize3_MATTR
    )
    expect_identical(
        textstat_lexdiv(mytoken, measure = "MATTR", MATTR_window = 4)[["MATTR"]],
        wsize4_MATTR
    )

    expect_warning(
        textstat_lexdiv(mytoken, measure = "MATTR", MATTR_window = 100),
        "MATTR_window exceeds some documents' token lengths, resetting to 7"
    )
})

test_that("textstat_lexdiv.tokens MATTR works correctly in conjunction with static measures", {
    mytxt <- "one one two one one two one"
    mytoken <- tokens(mytxt)
    wsize2_MATTR <- (1/2 + 1 + 1 + 1/2 + 1 + 1) / 6

    expect_equivalent(
        textstat_lexdiv(mytoken, measure = c("TTR", "MATTR"), MATTR_window = 2),
        data.frame(textstat_lexdiv(mytoken, measure = "TTR"), MATTR = wsize2_MATTR)
    )
})

test_that("textstat_lexdiv.tokens MSTTR works correctly on its own", {
    mytxt <- "apple orange apple orange pear pear apple orange"
    mytoken <- tokens(mytxt)
    wsize2_MSTTR <- (2/2 + 2/2 + 1/2 + 2/2) / 4
    wsize3_MSTTR <- (2/3 + 2/3 ) / 2 # apple orange at the back is discarded
    wsize4_MSTTR <- (2/4 + 3/4) / 2

    # Test segment size = 2
    expect_equivalent(
        textstat_lexdiv(mytoken, measure = "MSTTR", MSTTR_segment = 2)[["MSTTR"]],
        wsize2_MSTTR
    )

    # Test segment size = 3
    expect_equivalent(
        textstat_lexdiv(mytoken, measure = "MSTTR", MSTTR_segment = 3)[[2]],
        wsize3_MSTTR
    )

    # Test segment size = 4
    expect_equivalent(textstat_lexdiv(mytoken, measure = "MSTTR", MSTTR_segment = 4)[[2]],
                      wsize4_MSTTR)

    # Test segment size = ntoken
    expect_equivalent(textstat_lexdiv(mytoken, measure = "MSTTR", MSTTR_segment = length(mytoken[["text1"]]))[[2]],
                      textstat_lexdiv(mytoken, measure = "TTR")[[2]])
})

test_that("textstat_lexdiv.tokens MSTTR works correctly in conjunction with static measures", {
    mytxt <- "apple orange apple orange pear pear apple orange"
    mytoken <- tokens(mytxt)
    wsize2_MSTTR <- (2/2 + 2/2 + 1/2 + 2/2) / 4

    expect_equivalent(
        textstat_lexdiv(mytoken, measure = c("TTR", "MSTTR"), MSTTR_segment = 2),
        data.frame(textstat_lexdiv(mytoken, measure = "TTR"), MSTTR = wsize2_MSTTR)
    )
})


test_that("compute_MSTTR internal function has working exception handlers", {
    mytxt <- "apple orange apple orange pear pear apple orange"
    mytoken <- tokens(mytxt)

    expect_warning(
        quanteda.textstats:::compute_msttr(mytoken, 20),
        "MSTTR_segment exceeds some documents' token lengths, resetting to 8"
    )

    # expect_identical(
    #     list(compute_msttr(mytoken,segment_size=2, mean_sttr = FALSE, all_segments=TRUE)),
    #     list(c(MSTTR_tokens1_2 = 2/2, MSTTR_tokens3_4 =  2/2, MSTTR_tokens5_6 = 1/2, MSTTR_tokens7_8 = 2/2))
    # )
    #
    # expect_identical(
    #     list(compute_msttr(mytoken,segment_size=3 , mean_sttr = FALSE, all_segments=TRUE, discard_remainder = FALSE)),
    #     list(c(MSTTR_tokens1_3 = 2/3, MSTTR_tokens4_6 =  2/3, MSTTR_tokens7_8 = 1))
    # )

    # Test misspecification of Segment Size
    expect_error(quanteda.textstats:::compute_msttr(mytoken, 0),
                 "MSTTR_segment must be positive")

    # # Case when neither mean segmental TTR or each segment TTR is not requested
    # expect_error(compute_msttr(mytoken,segment_size=2,mean_sttr = FALSE ,all_segments=FALSE),
    #              quanteda.textstats:::message_error("at least one MSTTR value type to be returned"))
})

test_that("textstat_lexdiv.tokens works right when all measures are requested", {
    skip("until all MA measures are made functional")
    mytxt <- "apple orange apple orange pear pear apple orange"
    mytoken <- tokens(mytxt)
    wsize2_MATTR <- (2/2 + 2/2 + 2/2 + 2/2 + 1/2 + 2/2 + 2/2) / 7
    wsize2_MSTTR <- (2/2 + 2/2 + 1/2 + 1) /4 # 7th entry is discarded

    static_measures <- c("TTR", "C", "R", "CTTR", "U", "S", "K", "D", "Vm", "Maas")
    moving_measures_df <- data.frame(MATTR = wsize2_MATTR, MSTTR = wsize2_MSTTR)

    expect_identical(textstat_lexdiv(mytoken,
                                     measure = "all",
                                     MATTR_window = 2,
                                     MSTTR_segment_size = 2
    ),
    cbind(textstat_lexdiv(mytoken, measure = static_measures),
          moving_measures_df))
})

test_that("textstat_lexdiv works with measure = 'all'", {
    res <- textstat_lexdiv(dfm(tokens("What, oh what, are we doing?")),
                           measure = "all")
    expect_true(
        setequal(names(res),
                 c("document", "TTR", "C", "R", "CTTR", "U", "S", "K", "I", "D", "Vm", "Maas", "lgV0", "lgeV0"))
    )
})

test_that("dfm_split_hyphenated_features works as expected", {
    dfmat <- dfm(tokens("One-two one two three."))
    expect_identical(
        featnames(quanteda.textstats:::dfm_split_hyphenated_features(dfmat)),
        c("one", "two", "three", ".", "-")
    )
})

test_that("Exact tests for Yule's K", {
    txt <- c("a b c d d e e f f f",
             "a b c d d e e f f f g g g g")
    toks <- tokens(txt)
    textstat_lexdiv(toks, "K")

    # from koRpus and in issue #46
    expect_equal(
        round(textstat_lexdiv(toks, "K")$K, 3),
        c(1000, 1122.449)
    )
})
