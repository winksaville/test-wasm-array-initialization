#include "./mem.h"

struct bd {
  char d;
};
static struct bd gBd[2] = {{1}, {2}};

static char gU8[2] = {3, 4};

char* get_gBdAddr(int idx) {
  return &gBd[idx].d;
}

char get_gBd(int idx) {
  return gBd[idx].d;
}

char* get_gU8Addr(int idx) {
  return &gU8[idx];
}

char get_gU8(int idx) {
  return gU8[idx];
}

