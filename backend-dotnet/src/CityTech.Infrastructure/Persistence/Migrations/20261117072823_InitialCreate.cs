using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CityTech.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "accounts",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    name = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    email = table.Column<string>(type: "nvarchar(254)", maxLength: 254, nullable: false),
                    email_normalized = table.Column<string>(type: "nvarchar(254)", maxLength: 254, nullable: false),
                    password_hash = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: false),
                    role = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    active = table.Column<bool>(type: "bit", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2(7)", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2(7)", nullable: false),
                    version = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_accounts", x => x.id);
                    table.CheckConstraint("CK_accounts_email_normalized_lowercase", "[email_normalized] = LOWER([email_normalized])");
                    table.CheckConstraint("CK_accounts_name_length", "LEN([name]) >= 2");
                    table.CheckConstraint("CK_accounts_role", "[role] IN ('CIDADAO', 'GESTOR')");
                    table.CheckConstraint("CK_accounts_version", "[version] >= 0");
                });

            migrationBuilder.CreateTable(
                name: "idempotency_records",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    scope = table.Column<string>(type: "nvarchar(120)", maxLength: 120, nullable: false),
                    idempotency_key = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    request_hash = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    status_code = table.Column<int>(type: "int", nullable: false),
                    response_body = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    created_at = table.Column<DateTime>(type: "datetime2(7)", nullable: false),
                    expires_at = table.Column<DateTime>(type: "datetime2(7)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_idempotency_records", x => x.id);
                    table.CheckConstraint("CK_idempotency_records_expiry", "[expires_at] > [created_at]");
                    table.CheckConstraint("CK_idempotency_records_key_length", "LEN([idempotency_key]) BETWEEN 8 AND 128");
                    table.CheckConstraint("CK_idempotency_records_request_hash", "LEN([request_hash]) = 64 AND [request_hash] = LOWER([request_hash])");
                    table.CheckConstraint("CK_idempotency_records_scope_length", "LEN([scope]) BETWEEN 1 AND 120");
                    table.CheckConstraint("CK_idempotency_records_status_code", "[status_code] BETWEEN 100 AND 599");
                });

            migrationBuilder.CreateTable(
                name: "follow_ups",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    user_id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    occurrence_id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    note = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2(7)", nullable: false),
                    updated_at = table.Column<DateTime>(type: "datetime2(7)", nullable: false),
                    version = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_follow_ups", x => x.id);
                    table.CheckConstraint("CK_follow_ups_note_not_blank", "[note] IS NULL OR LEN(LTRIM(RTRIM([note]))) > 0");
                    table.CheckConstraint("CK_follow_ups_version", "[version] >= 0");
                    table.ForeignKey(
                        name: "FK_follow_ups_accounts_user_id",
                        column: x => x.user_id,
                        principalTable: "accounts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "UX_accounts_email_normalized",
                table: "accounts",
                column: "email_normalized",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UX_follow_ups_user_id_occurrence_id",
                table: "follow_ups",
                columns: new[] { "user_id", "occurrence_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_idempotency_records_expires_at",
                table: "idempotency_records",
                column: "expires_at");

            migrationBuilder.CreateIndex(
                name: "UX_idempotency_records_scope_key",
                table: "idempotency_records",
                columns: new[] { "scope", "idempotency_key" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "follow_ups");

            migrationBuilder.DropTable(
                name: "idempotency_records");

            migrationBuilder.DropTable(
                name: "accounts");
        }
    }
}
