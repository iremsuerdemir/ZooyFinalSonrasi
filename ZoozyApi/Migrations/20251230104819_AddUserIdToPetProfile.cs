using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ZoozyApi.Migrations
{
    /// <inheritdoc />
    public partial class AddUserIdToPetProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "UserId",
                table: "PetProfiles",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_PetProfiles_UserId",
                table: "PetProfiles",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_PetProfiles_Users_UserId",
                table: "PetProfiles",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_PetProfiles_Users_UserId",
                table: "PetProfiles");

            migrationBuilder.DropIndex(
                name: "IX_PetProfiles_UserId",
                table: "PetProfiles");

            migrationBuilder.DropColumn(
                name: "UserId",
                table: "PetProfiles");
        }
    }
}
