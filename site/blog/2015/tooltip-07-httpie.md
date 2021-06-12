# Tooltip #7: httpie

<date>2015-11-07</date>
<tags>tooltip</tags>

You know `curl`. Well, you don't really _know_ know `curl`, because who could? It supports over 20 different protocols, and, I mean, the tool _itself_ basically confesses to being abstruse.

> The command is designed to work without user interaction.…As you will see below, the number of features will make your head spin!

Moreover,

```
man curl | wc -l
2640
```

With a man page like that, who needs enemies?

Anyway, for all those times you just want to make an HTTP request to somewhere, maybe with a custom header or two and a few parameters, but _you just know_ it would take less time to type your request out by hand into netcat than it would to figure out how to construct the right `curl` invocation, there's a better way.

## HTTP for humans ##

The Python-fluent among you probably know (and probably love) Kenneth Reitz's [`requests`](http://docs.python-requests.org/en/latest/) library. [HTTPie](https://github.com/jkbrzt/httpie) is essentially `requests`-the-CLI, but also with `pygments`-colored and pretty-printed output. Yeah, it's that nice.

Install it the usual way with `brew install httpie`, or with `apt-get`, or with `pip` if that's your thing.

It goes generally like this.

```
http GET localhost:3000/health
```

Options and flags go first, then the HTTP method, then the URL, and last some number of headers or parameters. That one above will print out the whole HTTP response, verbatim. It will syntax-highlight headers, and if the body is a format HTTPie knows about, like JSON, that will be colored and nicely formatted also.

Since `GET` is the default method and `localhost` is the default domain, the above can even be nicely elided.

```
http :3000/health
```

## An interface you can (basically) memorize ##

Constructing POST requests is about as simple as it can get.

```
http POST httpbin.org/post myparam=myvalue
```

This will, naturally, send a POST off to [httpbin](https://httpbin.org) (which is itself another fantastic Reitz tool, a gold standard for echo servers), complete with a request body of `{"myparam":"myvalue"}`. Conveniently, if you specify _any_ request parameters, HTTPie will know to send a POST instead of a GET. If you'd rather form-encode your request than send JSON, use `--form` or `-f` like so.

```
http --form httpbin.org/post myparam=myvalue
```

It's a friend to pipes, too, knowing to disable highlighting and printing of headers when redirected, and able to accept request bodies on stdin.

```
cat request.json | http httpbin.org/status/418 > teapot.txt
```

Similar to `key=value` style JSON parameters, you can also specify custom headers without hassle.

```
http httpbin.org/user-agent User-Agent:2sneaky4u
```

Several more forms of these are supported. Note they must always come at the end, after the URL part.

|Separator |Usage              |                                                                                                                       |
|----------|-------------------|-----------------------------------------------------------------------------------------------------------------------|
|`:`       |`X-Api-Token:1234` |HTTP Header                                                                                                            |
|`=`       |`param=value`      |Parameter in JSON or form-encoded if `--form` specified. If JSON, `value` is _always_ a string.                        |
|`:=`      |`param:=false`     |Parameter as _raw_ JSON, for use with non-string values                                                                |
|`==`      |`query==somequery` |Query parameter, so you don't have to escape or handle `?` and `&` yourself                                            |
|`:=@`     |`ids:=@ids.json`   |Like `:=`, but the contents of the file `ids.json` are used verbatim. It should already be valid JSON or form encoded. |
|`=@`      |`password=@pw.txt` |Like `=`, but the contents of the file `pw.txt` are form-encoded (`--form`) or put in a JSON string (default).         |
|`@`       |`file@upload.tar`  |Requires `--form`, and uploads the file `upload.tar` in a `multipart/form-data` request.                               |

## Other goodies ##

Download a file like `wget` with `--download` or `-d`.

```
http --download https://httpbin.org/image/jpeg
```

Get through a Basic auth challenge by giving your name with `--auth` or `-a` up front, and entering your password at the prompt.

```
http -a ryan https://httpbin.org/basic-auth/ryan/s00pers3krit
```

Control what things to print with `--print` or `-p`.

|Flag |Prints            |
|-----|------------------|
|H    |Request headers   |
|B    |Request body      |
|h    |response headers  |
|b    |response body     |

This will print the request and response headers without either body.

```
http --print=Hh httpbin.org/post k=v
```

You can also opt to print everything with `--verbose` or `-v`, which behaves like `--print=HBhb`.

A couple others worth mentioning are skipping SSL cert verification with `--verify=no`, and opting to keep cookies and authentication creds around in a named session file with `--session=test_session`. FYI, these session files are stored in plain text at `~/.httpie/sessions`.
