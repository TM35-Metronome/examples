#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFSIZE 1024 * 2
#define array_size(a) (sizeof(a) / sizeof(a[0]))

unsigned int pokemons = 0;
bool starters[3] = {false};

char *get_line(char *buf, size_t buf_size, char **start, char **end, size_t *len) {
    while (true) {
        size_t read, remain = (size_t)*end - (size_t)*start;
        char *result = *start;

        for (; *start < *end && **start != '\n'; (*start)++);
        if (*start < *end) {
            *len = (size_t)*start - (size_t)result;
            *start += 1;
            return result;
        }

        memcpy(buf, result, remain);
        *start = buf;
        *end = buf + remain;

        read = fread(*end, 1, (buf_size - remain), stdin);
        *end += read;
        if (read == 0) {
            *len = ((size_t)*end - (size_t)*start);
            *start = *end;
            return *len != 0 ? buf : NULL;
        }
    }
    return NULL;
}

int main() {
    unsigned int i;
    size_t len;
    char buf[BUFSIZE+1];
    char *start = buf;
    char *end = buf;
    char *line;

    while ((line = get_line(buf, BUFSIZE, &start, &end, &len))) {
        unsigned int index;

        line[len] = '\0';
        if (sscanf(line, ".starters[%u]=", &index) == 2
            && index < array_size(starters)) {
            starters[index] = true;
        } else {
            if (sscanf(line, ".pokemons[%u]", &index) == 1)
                pokemons = pokemons < index+1 ? index+1 : pokemons;

            line[len] = '\n';
            if (fwrite(line, 1, len+1, stdout) != len+1)
                goto error_path;
        }
    }

    srand(0);
    for (i = 0; i < array_size(starters); i++) {
        if (!starters[i])
            continue;

        if (fprintf(stdout, ".starters[%u]=%u\n", i, rand() % pokemons) < 0)
            goto error_path;
    }

    return 0;

error_path:
    return 1;
}
