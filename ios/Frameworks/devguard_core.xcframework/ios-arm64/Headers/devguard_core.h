#ifndef DEVGUARD_CORE_H
#define DEVGUARD_CORE_H

#include <stdint.h>
#include <stddef.h>

#if _WIN32
#define DEVGUARD_EXPORT __declspec(dllexport)
#else
#define DEVGUARD_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

DEVGUARD_EXPORT void generate_signature(const char* project_id, long long timestamp, char* output);
DEVGUARD_EXPORT int verify_response(const char* response_body, const char* signature);
DEVGUARD_EXPORT void secure_save_token(const char* token, char* output);
DEVGUARD_EXPORT void secure_get_token(const char* scrambled, char* output);
DEVGUARD_EXPORT void hash_sha256_hex(const char* input, char* output);
DEVGUARD_EXPORT void xor_transform(
    const char* input,
    size_t input_len,
    const char* key,
    size_t key_len,
    char* output
);
DEVGUARD_EXPORT void derive_log_key(const char* passcode, const char* salt, char* output);
DEVGUARD_EXPORT int get_total_ram_mb(void);

#endif // DEVGUARD_CORE_H
