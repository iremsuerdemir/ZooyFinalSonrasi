using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ZoozyApi.Migrations
{
    /// <inheritdoc />
    public partial class AddWeightToPetProfile : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Weight",
                table: "PetProfiles",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Weight",
                table: "PetProfiles");
        }
    }
}
