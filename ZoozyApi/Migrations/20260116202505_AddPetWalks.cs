using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ZoozyApi.Migrations
{
    /// <inheritdoc />
    public partial class AddPetWalks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PetWalks",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    UserId = table.Column<int>(type: "int", nullable: false),
                    DurationSeconds = table.Column<int>(type: "int", nullable: false),
                    DistanceKm = table.Column<double>(type: "float", nullable: false),
                    PathJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    PetsJson = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    Date = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PetWalks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PetWalks_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PetWalks_UserId",
                table: "PetWalks",
                column: "UserId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PetWalks");
        }
    }
}
