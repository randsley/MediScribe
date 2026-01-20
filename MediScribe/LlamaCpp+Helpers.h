#ifndef LLAMA_CPP_HELPERS_H
#define LLAMA_CPP_HELPERS_H

#import "llama.h"

#ifdef __cplusplus
extern "C" {
#endif

// Helper to get vocab from model
const struct llama_vocab * mediscribe_get_vocab(const struct llama_model * model);

// Helper to get n_vocab (deprecated in llama.cpp, but we provide wrapper)
int32_t mediscribe_vocab_n_tokens(const struct llama_vocab * vocab);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_CPP_HELPERS_H
