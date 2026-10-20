## `agentFiles.js`

### [readIfExists(file)](../../../agentFiles.js#L10)

Reads a file that may not be there.

- In: `file`, the absolute path to read.
- Out: the file's text. Null when the file is missing or cannot be read.

### [skillVersion(text)](../../../agentFiles.js#L18)

Reads the version marker that the shipped skill carries on the line `<!-- whatdoesthisdo-skill-version: … -->`.

- In: `text`, the text of a skill file, or null when there is none.
- Out: the version, `0.1.4`. Null when the text has no marker, as a skill installed before the marker existed.

### [isOlder(installed, bundled)](../../../agentFiles.js#L24)

Compares two dotted version numbers to decide whether an installed skill is behind the one the extension ships.

- In: `installed`, the version of the installed skill, or null when it has no marker. `bundled`, the version of the
  skill inside the extension.
- Out: true when the installed version is lower, number by number from the left, with a missing number counted as
  zero. True as well when there is no installed version, since a skill without a marker is older than any marker.

### [installPaths(base, scope)](../../../agentFiles.js#L43)

Names the three files an agent setup writes in one place.

- In: `base`, the absolute path of the place, an open folder or the home folder. `scope`, `project` or `global`.
- Out: the skill path, the `CLAUDE.md` path, which is at the root of a project and under `.claude` in the home
  folder, and the Cursor rule path, which is null for the home folder because Cursor keeps global rules in its
  settings.

### [installedFolder(base, scope)](../../../agentFiles.js#L51)

Finds the references folder a place was set up with, so an update keeps it.

- In: `base`, the absolute path of the place. `scope`, `project` or `global`.
- Out: the folder named on the skill's "The folder is …" line, else the one named in the rule block, else the
  default `docs/whatdoesthisdo/references`.

### [substitute(text, folder)](../../../agentFiles.js#L59)

Puts the user's references folder into a shipped agent file, which names the default folder everywhere.

- In: `text`, the text of a shipped agent file. `folder`, the references folder of the place being updated.
- Out: the text with every default folder path replaced by that folder.

### [installedSkillVersion(base, scope)](../../../agentFiles.js#L63)

Tells whether a place has the skill, and which version.

- In: `base`, the absolute path of the place. `scope`, `project` or `global`.
- Out: undefined when no skill is installed there. Otherwise the installed version, which is null for a skill
  without a marker.

### [bundledSkillVersion(agentDir)](../../../agentFiles.js#L69)

Reads the version of the skill the extension ships.

- In: `agentDir`, the absolute path of the extension's `agent` folder.
- Out: the version from the shipped skill's marker.

### [updateInstall(base, scope, agentDir)](../../../agentFiles.js#L74)

Brings one place up to date with the shipped agent files, touching only what is already installed there. The rule
block is replaced inside `CLAUDE.md` where it sits; the rest of the file is kept. A place that was set up for Cursor
only gets no `CLAUDE.md`.

- In: `base`, the absolute path of the place. `scope`, `project` or `global`. `agentDir`, the absolute path of the
  extension's `agent` folder.
- Out: the absolute paths of the files written, in the order skill, `CLAUDE.md`, Cursor rule. An empty list when
  nothing is installed there.

## Constants

- [`DEFAULT_FOLDER`](../../../agentFiles.js#L4): the references folder the shipped agent files name, replaced by the user's choice on
  install and on update.
- [`SKILL_VERSION`](../../../agentFiles.js#L5): matches the version marker line of the skill and captures the version.
- [`SKILL_FOLDER`](../../../agentFiles.js#L6): matches the skill line that names the references folder and captures the folder.
- [`BLOCK_FOLDER`](../../../agentFiles.js#L7): matches the rule block line that names the references folder and captures the folder.
- [`BLOCK`](../../../agentFiles.js#L7): matches the whole rule block in `CLAUDE.md`, from its start marker to its end marker.
