package br.com.fiap.citytech.category;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class CategoryTests {

    @Test
    void constructorNormalizesCodeAndStartsActive() {
        var category = new Category(" vias ", " Vias ", " Pavimentação ");

        assertEquals("VIAS", category.getCode());
        assertEquals("Vias", category.getName());
        assertEquals("Pavimentação", category.getDescription());
        assertTrue(category.isActive());
    }

    @Test
    void updatePreservesStableCode() {
        var category = new Category("VIAS", "Vias", null);

        category.update("Ruas e calçadas", "Descrição");

        assertEquals("VIAS", category.getCode());
        assertEquals("Ruas e calçadas", category.getName());
    }

    @Test
    void deactivateIsIdempotent() {
        var category = new Category("VIAS", "Vias", null);

        category.deactivate();
        category.deactivate();

        assertFalse(category.isActive());
    }

    @Test
    void blankRequiredFieldsAreRejected() {
        assertThrows(IllegalArgumentException.class, () -> new Category(" ", "Vias", null));
        assertThrows(IllegalArgumentException.class, () -> new Category("VIAS", " ", null));
    }
}
