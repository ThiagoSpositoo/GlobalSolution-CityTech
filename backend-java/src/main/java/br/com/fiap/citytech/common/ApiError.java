package br.com.fiap.citytech.common;

import java.time.Instant;
import java.util.List;

public record ApiError(
        String type,
        String title,
        int status,
        String detail,
        String instance,
        String code,
        String traceId,
        Instant timestamp,
        List<FieldError> errors) {

    public record FieldError(String field, String message) {
    }
}
