package br.com.fiap.citytech.occurrence;

import br.com.fiap.citytech.common.PageResponse;
import br.com.fiap.citytech.history.HistoryResponse;
import br.com.fiap.citytech.security.AuthenticatedUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import java.net.URI;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/occurrences")
public class OccurrenceController {

    private final OccurrenceService service;

    public OccurrenceController(OccurrenceService service) {
        this.service = service;
    }

    @PostMapping
    @PreAuthorize("hasRole('CIDADAO')")
    public ResponseEntity<OccurrenceContracts.Response> create(
            @Valid @RequestBody OccurrenceContracts.CreateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        var response = service.create(request, AuthenticatedUser.from(jwt));
        return ResponseEntity
                .created(URI.create("/api/v1/occurrences/" + response.id()))
                .body(response);
    }

    @GetMapping
    public PageResponse<OccurrenceContracts.Summary> list(
            @RequestParam(required = false) OccurrenceStatus status,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(required = false) Priority priority,
            @RequestParam(required = false) @Size(min = 1, max = 120) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "createdAt,desc") String sort,
            @AuthenticationPrincipal Jwt jwt) {
        return service.list(
                status,
                categoryId,
                priority,
                q,
                page,
                size,
                sort,
                AuthenticatedUser.from(jwt));
    }

    @GetMapping("/{id}")
    public OccurrenceContracts.Response get(
            @PathVariable UUID id,
            @AuthenticationPrincipal Jwt jwt) {
        return service.get(id, AuthenticatedUser.from(jwt));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('CIDADAO')")
    public OccurrenceContracts.Response update(
            @PathVariable UUID id,
            @Valid @RequestBody OccurrenceContracts.UpdateRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return service.update(id, request, AuthenticatedUser.from(jwt));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancel(
            @PathVariable UUID id,
            @RequestParam long version,
            @RequestParam @Size(min = 1, max = 255) String reason,
            @AuthenticationPrincipal Jwt jwt) {
        service.cancel(id, version, reason, AuthenticatedUser.from(jwt));
        return ResponseEntity.noContent().build();
    }

    @PatchMapping("/{id}/triage")
    @PreAuthorize("hasRole('GESTOR')")
    public OccurrenceContracts.Response triage(
            @PathVariable UUID id,
            @Valid @RequestBody OccurrenceContracts.TriageRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return service.triage(id, request, AuthenticatedUser.from(jwt));
    }

    @PatchMapping("/{id}/status")
    public OccurrenceContracts.Response transition(
            @PathVariable UUID id,
            @Valid @RequestBody OccurrenceContracts.StatusRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return service.transition(id, request, AuthenticatedUser.from(jwt));
    }

    @GetMapping("/{id}/history")
    public PageResponse<HistoryResponse> history(
            @PathVariable UUID id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal Jwt jwt) {
        return service.history(id, page, size, AuthenticatedUser.from(jwt));
    }

    @PostMapping("/{id}/ai-suggestion/review")
    public OccurrenceContracts.Response reviewSuggestion(
            @PathVariable UUID id,
            @Valid @RequestBody OccurrenceContracts.ReviewRequest request,
            @AuthenticationPrincipal Jwt jwt) {
        return service.reviewSuggestion(id, request, AuthenticatedUser.from(jwt));
    }
}
