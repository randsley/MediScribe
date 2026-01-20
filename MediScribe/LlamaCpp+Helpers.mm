#import "LlamaCpp+Helpers.h"

const struct llama_vocab * mediscribe_get_vocab(const struct llama_model * model) {
    return llama_model_get_vocab(model);
}

int32_t mediscribe_vocab_n_tokens(const struct llama_vocab * vocab) {
    return llama_vocab_n_tokens(vocab);
}
