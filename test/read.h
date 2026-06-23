#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 256

char* sys_getcmd(const char* cmd) {
    FILE *pipe = popen(cmd, "r");
    if (pipe == NULL) {
        perror("Failed to run command");
        return NULL;
    }

    size_t dynamic_size = BUFFER_SIZE;
    char* end = malloc(dynamic_size);
    if (end == NULL) {
        pclose(pipe);
        return NULL;
    }
    end[0] = '\0';

    char buffer[BUFFER_SIZE];
    while (fgets(buffer, sizeof(buffer), pipe) != NULL) {
        size_t current_len = strlen(end);
        size_t incoming_len = strlen(buffer);

        if (current_len + incoming_len >= dynamic_size) {
            dynamic_size *= 2;
            char* temp = realloc(end, dynamic_size);
            if (temp == NULL) {
                free(end);
                pclose(pipe);
                return NULL;
            }
            end = temp;
        }
        strcat(end, buffer);
    }
    pclose(pipe);
    return end;
}

struct e_res {
    int code = -22;
    char* message;
};

e_res sys_exec(const char* cmd) {
    e_res res;
    res.message = sys_getcmd(cmd);
    res.code = atoi(sys_getcmd("echo $LASTEXITCODE"));
    return res;
}
