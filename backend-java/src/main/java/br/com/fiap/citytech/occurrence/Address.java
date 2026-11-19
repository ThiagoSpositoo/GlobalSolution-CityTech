package br.com.fiap.citytech.occurrence;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
public class Address {

    @Column(name = "address_street", nullable = false, length = 160)
    private String street;

    @Column(name = "address_number", nullable = false, length = 20)
    private String number;

    @Column(name = "address_complement", length = 80)
    private String complement;

    @Column(name = "address_district", nullable = false, length = 100)
    private String district;

    @Column(name = "address_city", nullable = false, length = 100)
    private String city;

    @Column(name = "address_state", nullable = false, length = 2)
    private String state;

    @Column(name = "address_postal_code", length = 9)
    private String postalCode;

    protected Address() {
    }

    public Address(
            String street,
            String number,
            String complement,
            String district,
            String city,
            String state,
            String postalCode) {
        this.street = required(street, "street");
        this.number = required(number, "number");
        this.complement = optional(complement);
        this.district = required(district, "district");
        this.city = required(city, "city");
        this.state = required(state, "state").toUpperCase(java.util.Locale.ROOT);
        this.postalCode = optional(postalCode);
    }

    public String getStreet() {
        return street;
    }

    public String getNumber() {
        return number;
    }

    public String getComplement() {
        return complement;
    }

    public String getDistrict() {
        return district;
    }

    public String getCity() {
        return city;
    }

    public String getState() {
        return state;
    }

    public String getPostalCode() {
        return postalCode;
    }

    private static String required(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(field + " é obrigatório.");
        }
        return value.trim();
    }

    private static String optional(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
