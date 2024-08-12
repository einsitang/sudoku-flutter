# CONTRIBUTING GUIDE

We welcome open source contributions in the following ways

- Provide functional/interactive/stylistic suggestions for the project on issue
- Report bugs with detail information on issue
- Improve or correct documentation
- Application language localization translation
- Contribute your code via `PR`

## contributing via Pull Requests

start by`fork` this repository to your personal account on github

clone your fork project to your local machine
```shell
git clone https://github.com/YOUR_USER_NAME/sudoku-flutter
```
add remote alias `upstream` to official project
```shell
git remote add upstream https://github.com/einsitang/sudoku-flutter
```
ensure that the latest repository code is synchronized , we recommend you contributing on branch `develop`
```shell
git checkout upstream/develop
git pull upstream develop -f
```
modify the code and commit/push to your repository

```shell
git checkout develop
# ....change code on your machine
git commit -am "comment with your changes"
git merge upstream/develop
git push origin develop
```

create a `Pull Request` on github

> [!IMPORTANT] 
> Remember checkout branch `upstream/develop` and resolve conflict before submitting a `Pull Request`

## code style

format your code as much as possible,

you can use command `dart format .` to format your code

## editor

we recommend using `IDEA` to work on this project , but not mandatory.
