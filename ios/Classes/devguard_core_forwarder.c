#include <stdint.h>

// Forward declaration of the native functions
void generate_signature(const char* project_id, int64_t timestamp, char* output);
int verify_response(const char* response_body, const char* signature);
void hash_sha256_hex(const char* input, char* output);
void xor_transform(const char* input, size_t input_len, const char* key, size_t key_len, char* output);
void derive_log_key(const char* passcode, const char* salt, char* output);
int get_total_ram_mb(void);

// Ensures the linker includes symbols from the static library for FFI lookup.
void devguard_dummy_reference() {
    char buf[65];
    generate_signature("", 0, buf);
    verify_response("", "");
    hash_sha256_hex("", buf);
    xor_transform("", 0, "", 0, buf);
    derive_log_key("", "", buf);
    get_total_ram_mb();
}
