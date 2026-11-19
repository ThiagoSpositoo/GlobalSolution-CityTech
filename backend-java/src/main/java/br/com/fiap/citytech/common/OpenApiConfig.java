package br.com.fiap.citytech.common;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI cityTechOpenApi() {
        var scheme = new SecurityScheme()
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT")
                .description("JWT RS256 emitido pela API .NET.");
        return new OpenAPI()
                .info(new Info()
                        .title("CityTech API Java")
                        .version("v1")
                        .description("Ocorrências, categorias, histórico e gestão urbana."))
                .components(new Components().addSecuritySchemes("Bearer", scheme))
                .addSecurityItem(new SecurityRequirement().addList("Bearer"));
    }
}
