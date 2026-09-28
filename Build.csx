#r "nuget: Tsinswreng.CsSh, 0.3.0-alpha"
#r "nuget: OpenCC, 0.1.0"
#nullable enable
using CT = System.Threading.CancellationToken;
using Tsinswreng.CsSh;
using static Tsinswreng.CsSh.ShGlobal;

using OpenCC;

CT Ct = default;

string Dir = CsxDir();
await Write(Dir+"/README.md", await TypstToMd(await Read(Dir+"/README.typ", Ct), Dir, Ct), Ct);

// typst 源 -> Markdown。兩步都走 stdin/stdout 管道，不落任何臨時文件。
// Root 供 typst 解析相對的 #include/#import；stdin 模式下相對路徑按 Root 解析，自包含的文檔可傳 null。
static async Task<string> TypstToMd(Content Src, Pth? Root, CT Ct){
	var Html = await Cmd("typst", new[]{"compile","-","-","--format","html","--features","html"},
		new (Stdin: Src, Cwd: Root)).Text(Ct);
	if(!Html.Exit.IsSuccess){ throw new Exception($"typst 失敗({Html.Exit.ExitCode}): {Html.Stderr}"); }
	var Md = await Cmd("pandoc", new[]{"-f","html","-t","gfm","--wrap=none"},
		new (Stdin: Html.Stdout)).Text(Ct);
	if(!Md.Exit.IsSuccess){ throw new Exception($"pandoc 失敗({Md.Exit.ExitCode}): {Md.Stderr}"); }
	return Md.Stdout;
}