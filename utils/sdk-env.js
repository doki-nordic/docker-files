import * as std from "std";

const vars = [
    {
      "type": "relative_paths",
      "key": "PERL5LIB",
      "values": [
        "etc/perl",
        "usr/local/lib/x86_64-linux-gnu/perl/5.30.0",
        "usr/local/share/perl/5.30.0",
        "usr/lib/x86_64-linux-gnu/perl5/5.30",
        "usr/share/perl5",
        "usr/lib/x86_64-linux-gnu/perl/5.30",
        "usr/share/perl/5.30",
        "usr/local/lib/site_perl",
        "usr/lib/x86_64-linux-gnu/perl-base"
      ],
      "existing_value_treatment": "overwrite"
    },
    {
      "type": "relative_paths",
      "key": "PERLLIB",
      "values": [
        "etc/perl",
        "usr/local/lib/x86_64-linux-gnu/perl/5.30.0",
        "usr/local/share/perl/5.30.0",
        "usr/lib/x86_64-linux-gnu/perl5/5.30",
        "usr/share/perl5",
        "usr/lib/x86_64-linux-gnu/perl/5.30",
        "usr/share/perl/5.30",
        "usr/local/lib/site_perl",
        "usr/lib/x86_64-linux-gnu/perl-base"
      ],
      "existing_value_treatment": "overwrite"
    },
    {
      "type": "relative_paths",
      "key": "TCL_LIBRARY",
      "values": [
        "usr/local/lib/tcl8.6"
      ],
      "existing_value_treatment": "overwrite"
    },
    {
      "type": "relative_paths",
      "key": "TK_LIBRARY",
      "values": [
        "usr/local/lib/tk8.6"
      ],
      "existing_value_treatment": "overwrite"
    }
];

const filePath = scriptArgs[1];
if (!filePath) {
	std.err.puts("Usage: qjs sdk-env.js <json-file>\n");
	std.exit(1);
}

const content = std.loadFile(filePath);
if (content === null) {
	std.err.puts(`Failed to read file: ${filePath}\n`);
	std.exit(1);
}

let data;
try {
	data = JSON.parse(content);
} catch (error) {
	std.err.puts(`Invalid JSON in file: ${filePath}\n`);
	std.exit(1);
}

if (!Array.isArray(data.env_vars)) {
	data.env_vars = [];
}

for (const item of vars) {
	data.env_vars.push(item);
}

const file = std.open(filePath, "w");
if (!file) {
	std.err.puts(`Failed to open file for writing: ${filePath}\n`);
	std.exit(1);
}

const jsonOutput = JSON.stringify(data, null, 2) + "\n";
file.puts(jsonOutput);
const closeResult = file.close();
if (closeResult !== 0) {
	std.err.puts(`Failed to write file: ${filePath}\n`);
	std.exit(1);
}
