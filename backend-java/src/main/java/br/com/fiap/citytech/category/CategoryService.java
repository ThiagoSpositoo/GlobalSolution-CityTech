package br.com.fiap.citytech.category;

import br.com.fiap.citytech.common.ApiException;
import java.util.List;
import java.util.UUID;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CategoryService {

    private final CategoryRepository repository;

    public CategoryService(CategoryRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public List<CategoryContracts.Response> list(boolean includeInactive, boolean manager) {
        if (includeInactive && !manager) {
            throw new ApiException(
                    HttpStatus.FORBIDDEN,
                    "FORBIDDEN",
                    "Acesso negado",
                    "Somente gestores podem consultar categorias inativas.");
        }
        var categories = includeInactive
                ? repository.findAllByOrderByNameAsc()
                : repository.findAllByActiveTrueOrderByNameAsc();
        return categories.stream().map(CategoryContracts.Response::from).toList();
    }

    @Transactional
    public CategoryContracts.Response create(CategoryContracts.CreateRequest request) {
        if (repository.findByCodeIgnoreCase(request.code()).isPresent()) {
            throw duplicate();
        }
        try {
            return CategoryContracts.Response.from(repository.saveAndFlush(
                    new Category(request.code(), request.name(), request.description())));
        } catch (DataIntegrityViolationException exception) {
            throw duplicate();
        }
    }

    @Transactional
    public CategoryContracts.Response update(UUID id, CategoryContracts.UpdateRequest request) {
        var category = get(id);
        if (!category.getCode().equalsIgnoreCase(request.code())) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "VALIDATION_ERROR",
                    "Requisição inválida",
                    "O código estável da categoria não pode ser alterado.");
        }
        category.update(request.name(), request.description());
        return CategoryContracts.Response.from(category);
    }

    @Transactional
    public void deactivate(UUID id) {
        get(id).deactivate();
    }

    @Transactional(readOnly = true)
    public Category active(UUID id) {
        var category = get(id);
        if (!category.isActive()) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_CATEGORY",
                    "Categoria inválida",
                    "A categoria está inativa.");
        }
        return category;
    }

    @Transactional(readOnly = true)
    public Category get(UUID id) {
        return repository.findById(id).orElseThrow(() -> new ApiException(
                HttpStatus.NOT_FOUND,
                "NOT_FOUND",
                "Não encontrado",
                "A categoria não existe."));
    }

    private static ApiException duplicate() {
        return new ApiException(
                HttpStatus.CONFLICT,
                "CATEGORY_ALREADY_EXISTS",
                "Categoria duplicada",
                "Já existe uma categoria com o código informado.");
    }
}
