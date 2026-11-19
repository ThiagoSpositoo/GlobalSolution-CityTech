package br.com.fiap.citytech.category;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import br.com.fiap.citytech.common.ApiException;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CategoryServiceTests {

    @Mock
    private CategoryRepository repository;

    private CategoryService service;

    @BeforeEach
    void setUp() {
        service = new CategoryService(repository);
    }

    @Test
    void citizenCannotIncludeInactiveCategories() {
        assertThrows(ApiException.class, () -> service.list(true, false));
    }

    @Test
    void listUsesActiveQueryForCitizen() {
        when(repository.findAllByActiveTrueOrderByNameAsc())
                .thenReturn(List.of(new Category("VIAS", "Vias", null)));

        var result = service.list(false, false);

        assertEquals(1, result.size());
        verify(repository).findAllByActiveTrueOrderByNameAsc();
    }

    @Test
    void duplicateCodeIsRejectedBeforeInsert() {
        when(repository.findByCodeIgnoreCase("VIAS"))
                .thenReturn(Optional.of(new Category("VIAS", "Vias", null)));

        assertThrows(
                ApiException.class,
                () -> service.create(new CategoryContracts.CreateRequest(
                        "VIAS",
                        "Outra",
                        null)));
    }

    @Test
    void createPersistsNormalizedCategory() {
        when(repository.findByCodeIgnoreCase("vias")).thenReturn(Optional.empty());
        when(repository.saveAndFlush(any(Category.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        var response = service.create(new CategoryContracts.CreateRequest(
                "vias",
                "Vias",
                null));

        assertEquals("VIAS", response.code());
    }

    @Test
    void updateRejectsCodeChange() {
        var id = UUID.randomUUID();
        when(repository.findById(id))
                .thenReturn(Optional.of(new Category("VIAS", "Vias", null)));

        assertThrows(
                ApiException.class,
                () -> service.update(
                        id,
                        new CategoryContracts.UpdateRequest("AGUA", "Água", null)));
    }
}
