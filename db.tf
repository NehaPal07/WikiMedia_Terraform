provider "mysql" {
  endpoint = "my-database.example.com:3306"
  username = "root"
  password = "root"
}

# Create a Database
resource "mysql_database" "wikidatabase" {
  name = "wikidatabase"

}
# Create a User
resource "mysql_user" "wiki" {
  user               = "wiki"
  host               = "example.com"
  plaintext_password = "THISpasswordSHOULDbeCHANGED"
}

#Grant
resource "mysql_grant" "wiki" {
  user       = "${mysql_user.wiki.user}"
  host       = "${mysql_user.wiki.host}"
  database   = "wikidatabase"
  privileges = ["SELECT", "UPDATE"]
}
~
