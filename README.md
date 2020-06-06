# DOCSEARCH

## Goal

First of all, I have a terrible memory and I always forget to backup notes, browsers bookmarks...

So, I tried to build a tool that can search for versionned data (using git) of different kind

This project aims to defined searchable data in YAML file (arbitrarily structured) 
and save knowledge accross different `resources` directories (for example to separate 
personnal and your company knowledge).

Using YAML structured data enables to:
- define a generic structure
- validate data definition (using linter)
- easily use data for humans and programs

## Setup

### From git

```
$ cd HOME/perso/git/
$ git clone <repository>
```

### Configuration

```
$ cat ~/.bash_aliases
# ---------------------------
# DOCSEARCH
# ---------------------------
export DOCSEARCH_PATH="$HOME/perso/git/resources:$HOME/work/git/resources"
export DOCSEARCH_ROOT="$HOME/perso/git/docsearch"

export DOCSEARCH_COLORED=1

if [ -d "$DOCSEARCH_ROOT" ]; then
    alias docsearch="$DOCSEARCH_ROOT/docsearch.rb"

    # autocompletion
    if [ -f "$DOCSEARCH_ROOT/docsearch-completion.bash" ]; then
        . "$DOCSEARCH_ROOT/docsearch-completion.bash"
    fi
fi
```

## Usage

### Command line help

```
Usage: docsearch.rb [ FILTERS ] -s PATTERN
    -C, --cheats                     Restrict search on cheatsheets terms
    -G, --glossary                   Restrict search on glossary terms
    -L, --links                      Restrict search on links terms
    -e, --env                        Show useful DOCSEARCH_* environment variables
    -c, --colored                    Enable colored output
    -i, --inventory                  List all availabled topics
    -j, --json                       JSON output
    -p, --pwd                        Show matched file found
    -m, --match-colored              Enable colored match
    -s, --search terms               Keyword or term to search
    -t, --topic topic                Search on a specific topic
```
### Examples

```
$ export DOCSEARCH_PATH="/tmp/docsearch-example/perso:/tmp/docsearch-example/work"
```

#### View DOCSEARCH environment
```
$ docsearch -e 

[*] DOCSEARCH_COLORED
color mode enabled

[*] DOCSEARCH_PATH
/tmp/docsearch-example/perso
/tmp/docsearch-example/work

```

#### View topics inventory
```
$ docsearch -i
[*] /tmp/docsearch-example/perso
git

[*] /tmp/docsearch-example/work
kubernetes
```

#### Simple search
```
$ docsearch -s check
[git] check submodules status
- git submodule status

[kubernetes] check kubectl version
- kubectl version --client
```

#### Search based on a specific topic
```
$ docsearch -s check -t kubernetes
[kubernetes] check kubectl version
- kubectl version --client
```

#### View full topic (aka `cat topic.yaml`)
```
$ docsearch -t kubernetes
[kubernetes] documentation
- https://kubernetes.io/docs/home/

[kubernetes] nodes
- set of worker machines

[kubernetes] check kubectl version
- kubectl version --client

```

#### Filter results based on data type
```
# Just links
$ docsearch -t kubernetes -L
[kubernetes] documentation
- https://kubernetes.io/docs/home/

# Just cheats
$ docsearch -t kubernetes -C
[kubernetes] check kubectl version
- kubectl version --client

# Just glossary
$ docsearch -t kubernetes -G
[kubernetes] nodes
- set of worker machines

```

#### JSON output

```
$ docsearch -t kubernetes -j | jq
{
  "cheats": [
    {
      "description": "check kubectl version",
      "data": [
        "kubectl version --client"
      ]
    }
  ],
  "glossary": [
    {
      "description": "nodes",
      "data": [
        "set of worker machines"
      ]
    }
  ],
  "links": [
    {
      "description": "documentation",
      "data": [
        "https://kubernetes.io/docs/home/"
      ]
    }
  ]
}
```

and more...

## Technical information

### Resources

Resources are paths where you want to stored your YAML files.

This design enables to store data in different location on your workstation and 
use a versionning system (like git).

You will need to define them as an environment variable named `DOCSEARCH_PATH`

Example

```
export DOCSEARCH_PATH="$HOME/perso/git/resources:$HOME/work/git/resources"
```

### Data

For the moment, data can be `links`, `cheats` or `glossary` and 
stored in YAML files named `<topic>.yaml` such as:
```
$ cd $HOME/git/resources
$ cat kubernetes.yaml
links:
    -
        description: "documentation"
        data:
            - "https://kubernetes.io/docs/home/"
    -
        ...

glossary:
    -
        description: "nodes"
        data:
            - "set of worker machines"
    -
        ...

cheats:
    -
        description: "check kubectl version"
        data:
            - "kubectl version --client"
    -
        ...
```

### Search mechanism

Searches are performed over the `description` fields.
It is a simple regex matching.

## Notes

This script has been developed using `ruby 2.5`.

## License

`docsearch` is available under the [Beerware](http://en.wikipedia.org/wiki/Beerware) license.
If we meet some day, and you think this stuff is worth it, you can buy me a beer in return.
