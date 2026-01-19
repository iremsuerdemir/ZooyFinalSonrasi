using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ZoozyApi.Migrations
{
    /// <inheritdoc />
    public partial class AddTargetUserIdToUserFavorite : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "TargetUserId",
                table: "UserFavorites",
                type: "int",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TargetUserId",
                table: "UserFavorites");
        }
    }
}
