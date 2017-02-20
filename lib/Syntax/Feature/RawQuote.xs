#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <stdlib.h>

#define MY_PKG "Syntax::Feature::RawQuote"
#define HINTK_KEYWORDS MY_PKG "/keywords"

static int enabled(pTHX_ const char *kw_ptr, STRLEN kw_len) {
  HV *hints;
  SV *sv, **psv;
  char *p, *pv;
  STRLEN pv_len;


  // No hints in effect
  if (!(hints = GvHV(PL_hintgv))) {
    return 0;
  }

  // No keywords in effect
  if (!(psv = hv_fetchs(hints, HINTK_KEYWORDS, 0))) {
    return 0;
  }

  sv = *psv;

  pv = SvPV(sv, pv_len);
  
  for (p = pv;
      (p = strchr(p + 1, *kw_ptr)) &&
      p <= pv + pv_len - kw_len;
      ) {
    if (p[-1] == ',' &&
        ((p + kw_len == pv + pv_len) || p[kw_len] == ',') &&
        memcmp(kw_ptr, p, kw_len) == 0
       ) {
      return 1;
    }
  }
  return 0;
}

static STRLEN matching_delimiter(pTHX_ I32 delim, char *ender) {
  char *p;

  switch (delim) {
    case '[':
      ender[0] = ']';
      return 1;
    case '{':
      ender[0] = '}';
      return 1;
    case '<':
      ender[0] = '>';
      return 1;
    case '(':
      ender[0] = ')';
      return 1;
    default:
      p = uvchr_to_utf8(ender, delim);
      return p - ender;
  }
}

static OP* make_op(pTHX) {
  SV *str = newSVpvn("", 0);
  I32 delim, catflags;
  char ender[UTF8_MAXBYTES];
  STRLEN ender_len;
  char *end;

  lex_read_space(0);
  delim = lex_read_unichar(0);
  ender_len = matching_delimiter(aTHX_ delim, ender);

  catflags = lex_bufutf8() ? SV_CATUTF8 : SV_CATBYTES;

  while ((end = memmem(PL_parser->bufptr, PL_parser->bufend - PL_parser->bufptr, ender, ender_len)) == NULL) {
    sv_catpvn_flags(str, PL_parser->bufptr, PL_parser->bufend - PL_parser->bufptr, catflags);
    lex_read_to(PL_parser->bufend);
    if (!lex_next_chunk(0)) {
      croak("no delimiter before EOF");
    }
  }
  sv_catpvn_flags(str, PL_parser->bufptr, end - PL_parser->bufptr, catflags);
  lex_read_to(end + ender_len);

  return newSVOP(OP_CONST, 0, str);
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw_ptr, STRLEN kw_len, OP **op_ptr) {
  if (enabled(aTHX_ kw_ptr, kw_len)) {
    *op_ptr = make_op(aTHX);
    return KEYWORD_PLUGIN_EXPR;
  } else {
    return next_keyword_plugin(aTHX_ kw_ptr, kw_len, op_ptr);
  }
}

MODULE = Syntax::Feature::RawQuote   PACKAGE = Syntax::Feature::RawQuote
PROTOTYPES: ENABLE

BOOT:
{
  HV *const stash = gv_stashpvs(MY_PKG, GV_ADD);
  newCONSTSUB(stash, "HINTK_KEYWORDS", newSVpvs(HINTK_KEYWORDS));
  next_keyword_plugin = PL_keyword_plugin;
  PL_keyword_plugin = my_keyword_plugin;
}
