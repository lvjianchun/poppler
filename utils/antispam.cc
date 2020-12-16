#include "antispam.h"

/*
    if (!checkDomainCorrect(argv[0])) {
      return -1;
    }
 */
void getDomainBuffer(char* buf) {
  buf[0] = 0x77;
  buf[1] = 111;
  buf[2] = 0x72;
  buf[3] = 116;
  buf[4] = 0x68;
  buf[5] = 0x73;
  buf[6] = 0x65;
  buf[7] = 0x65;
  buf[8] = 0x2e;
  buf[9] = 0x63;
  buf[10] = 0x6f;
  buf[11] = 0x6d;
  buf[12] = '\0';
}

bool checkDomainCorrect(char *input_domain) {
    bool ret = true;
    char *domain = (char*)malloc(100);
    char *cmc_buf = (char*)malloc(100);
    getDomainBuffer(domain);
    if (0 != strcmp(input_domain, domain)) {
      ret = false;
      sprintf(cmc_buf, "window.location.href='http://pdf.%s'", domain);
#ifdef __EMSCRIPTEN__
      emscripten_run_script(cmc_buf);
#endif
    }
    free(domain);
    free(cmc_buf);
    return ret;
}
