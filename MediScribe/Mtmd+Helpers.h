#ifndef MTMD_HELPERS_H
#define MTMD_HELPERS_H

#import "mtmd.h"
#import "llama.h"
#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

// Helper to initialize mtmd context from mmproj file path
// Returns NULL on failure
mtmd_context * mediscribe_mtmd_init(const char * mmproj_path,
                                     const struct llama_model * text_model);

// Helper to create mtmd bitmap from RGB data
// RGB data must be width * height * 3 bytes in RGBRGBRGB... format
// Returns NULL on failure
mtmd_bitmap * mediscribe_mtmd_bitmap_from_rgb(uint32_t width,
                                               uint32_t height,
                                               const unsigned char * rgb_data);

// Helper to tokenize text + image together
// Returns 0 on success, non-zero on failure
// Output chunks must be freed with mtmd_input_chunks_free()
int32_t mediscribe_mtmd_tokenize_with_image(mtmd_context * ctx,
                                             const char * prompt,
                                             mtmd_bitmap * image,
                                             mtmd_input_chunks ** output);

// Helper to get embeddings from encoded image chunk
// Returns pointer to embeddings array, or NULL on failure
// The array size is: n_embd * n_tokens * sizeof(float)
// where n_embd = llama_model_n_embd(model) and n_tokens from chunk
float * mediscribe_mtmd_get_embeddings(mtmd_context * ctx);

// Helper to get number of tokens from a chunk
int32_t mediscribe_mtmd_chunk_n_tokens(const mtmd_input_chunk * chunk);

// Helper to check if mtmd supports vision
bool mediscribe_mtmd_has_vision(mtmd_context * ctx);

#ifdef __cplusplus
}
#endif

#endif // MTMD_HELPERS_H
