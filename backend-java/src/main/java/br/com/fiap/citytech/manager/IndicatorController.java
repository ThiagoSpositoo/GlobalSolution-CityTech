package br.com.fiap.citytech.manager;

import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/manager")
public class IndicatorController {

    private final IndicatorService service;

    public IndicatorController(IndicatorService service) {
        this.service = service;
    }

    @GetMapping("/indicators")
    @PreAuthorize("hasRole('GESTOR')")
    public IndicatorService.Indicators indicators() {
        return service.indicators();
    }
}
