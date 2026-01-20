#import "Mtmd+Helpers.h"
#import <Foundation/Foundation.h>

mtmd_context * mediscribe_mtmd_init(const char * mmproj_path,
                                     const struct llama_model * text_model) {
    if (!mmproj_path || !text_model) {
        return NULL;
    }

    struct mtmd_context_params params = mtmd_context_params_default();
    params.use_gpu = true;
    params.print_timings = false;

    return mtmd_init_from_file(mmproj_path, text_model, params);
}

mtmd_bitmap * mediscribe_mtmd_bitmap_from_rgb(uint32_t width,
                                               uint32_t height,
                                               const unsigned char * rgb_data) {
    if (!rgb_data || width == 0 || height == 0) {
        return NULL;
    }

    return mtmd_bitmap_init(width, height, rgb_data);
}

int32_t mediscribe_mtmd_tokenize_with_image(mtmd_context * ctx,
                                             const char * prompt,
                                             mtmd_bitmap * image,
                                             mtmd_input_chunks ** output) {
    if (!ctx || !prompt || !image || !output) {
        return -1;
    }

    // Create input chunks
    *output = mtmd_input_chunks_init();
    if (!*output) {
        return -1;
    }

    // Prepare text input with default settings
    struct mtmd_input_text text_input;
    text_input.text = prompt;
    text_input.add_special = true;
    text_input.parse_special = true;

    // Tokenize with single image
    const mtmd_bitmap * bitmaps[] = { image };
    int32_t result = mtmd_tokenize(ctx, *output, &text_input, bitmaps, 1);

    if (result != 0) {
        mtmd_input_chunks_free(*output);
        *output = NULL;
    }

    return result;
}

float * mediscribe_mtmd_get_embeddings(mtmd_context * ctx) {
    if (!ctx) {
        return NULL;
    }

    return mtmd_get_output_embd(ctx);
}

int32_t mediscribe_mtmd_chunk_n_tokens(const mtmd_input_chunk * chunk) {
    if (!chunk) {
        return 0;
    }

    return (int32_t)mtmd_input_chunk_get_n_tokens(chunk);
}

bool mediscribe_mtmd_has_vision(mtmd_context * ctx) {
    if (!ctx) {
        return false;
    }

    return mtmd_support_vision(ctx);
}
