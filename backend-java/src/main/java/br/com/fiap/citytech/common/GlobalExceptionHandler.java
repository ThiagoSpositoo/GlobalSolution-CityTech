package br.com.fiap.citytech.common;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(ApiException.class)
    ResponseEntity<ApiError> handleApi(ApiException exception, HttpServletRequest request) {
        return response(
                exception.status(),
                exception.code(),
                exception.title(),
                exception.getMessage(),
                request,
                null);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ApiError> handleValidation(
            MethodArgumentNotValidException exception,
            HttpServletRequest request) {
        var errors = exception.getBindingResult().getFieldErrors().stream()
                .map(error -> new ApiError.FieldError(error.getField(), message(error)))
                .toList();
        return response(
                HttpStatus.BAD_REQUEST,
                "VALIDATION_ERROR",
                "Requisição inválida",
                "Corrija os campos informados.",
                request,
                errors);
    }

    @ExceptionHandler({
        HttpMessageNotReadableException.class,
        ConstraintViolationException.class
    })
    ResponseEntity<ApiError> handleMalformed(Exception exception, HttpServletRequest request) {
        return response(
                HttpStatus.BAD_REQUEST,
                "VALIDATION_ERROR",
                "Requisição inválida",
                "O corpo ou os parâmetros informados são inválidos.",
                request,
                null);
    }

    @ExceptionHandler(ObjectOptimisticLockingFailureException.class)
    ResponseEntity<ApiError> handleConcurrency(
            ObjectOptimisticLockingFailureException exception,
            HttpServletRequest request) {
        return response(
                HttpStatus.CONFLICT,
                "CONCURRENT_MODIFICATION",
                "Conflito de alteração",
                "O recurso foi alterado por outra requisição.",
                request,
                null);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<ApiError> handleIntegrity(
            DataIntegrityViolationException exception,
            HttpServletRequest request) {
        var traceId = traceId(request);
        LOGGER.warn("Conflito de integridade. traceId={}", traceId, exception);
        return response(
                HttpStatus.CONFLICT,
                "DATA_CONFLICT",
                "Conflito de dados",
                "A operação viola uma restrição de integridade.",
                request,
                null,
                traceId);
    }

    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<ApiError> handleAccessDenied(
            AccessDeniedException exception,
            HttpServletRequest request) {
        return response(
                HttpStatus.FORBIDDEN,
                "FORBIDDEN",
                "Acesso negado",
                "O usuário não possui permissão para esta operação.",
                request,
                null);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ApiError> handleUnexpected(Exception exception, HttpServletRequest request) {
        var traceId = traceId(request);
        LOGGER.error("Falha não tratada. traceId={}", traceId, exception);
        return response(
                HttpStatus.INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR",
                "Erro interno",
                "Não foi possível concluir a operação.",
                request,
                null,
                traceId);
    }

    private static ResponseEntity<ApiError> response(
            HttpStatus status,
            String code,
            String title,
            String detail,
            HttpServletRequest request,
            List<ApiError.FieldError> errors) {
        return response(status, code, title, detail, request, errors, traceId(request));
    }

    private static ResponseEntity<ApiError> response(
            HttpStatus status,
            String code,
            String title,
            String detail,
            HttpServletRequest request,
            List<ApiError.FieldError> errors,
            String traceId) {
        var body = new ApiError(
                "https://citytech.example/errors/" + code.toLowerCase().replace('_', '-'),
                title,
                status.value(),
                detail,
                request.getRequestURI(),
                code,
                traceId,
                Instant.now(),
                errors);
        return ResponseEntity.status(status).body(body);
    }

    private static String traceId(HttpServletRequest request) {
        var existing = request.getAttribute("citytech.traceId");
        if (existing instanceof String value) {
            return value;
        }
        var value = UUID.randomUUID().toString();
        request.setAttribute("citytech.traceId", value);
        return value;
    }

    private static String message(FieldError error) {
        return error.getDefaultMessage() == null ? "valor inválido" : error.getDefaultMessage();
    }
}
