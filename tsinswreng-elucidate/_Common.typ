#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#import "@preview/cuti:0.4.0": regex-fakebold, show-cn-fakebold, show-cn-fakeitalic
#import "@preview/numbly:0.1.0": numbly
#let H = auto-heading
#let P(C) = {
	h(2em)
	C
}
#let U(C)={
	underline(C)
}

// `--input bundle=true` 啓用 bundle 導出。
// 未傳入時保持普通文檔模式，方便 Tinymist 預覽。
#let IsBundle = sys.inputs.at("bundle", default: "false") == "true"

#let TargetPdf = "Pdf"
#let TargetHtml = "Html"
#let Target = sys.inputs.at("Target", default: TargetPdf)
#let Lang = sys.inputs.at("Lang", default: "zh-Hant")
#let LangParts = Lang.split("-")
#let TypstLang = LangParts.first()
#let LangFamily = if LangParts.len() >= 2 {
	LangParts.at(0) + "-" + LangParts.at(1)
} else {
	Lang
}
#let FigureSupplement = if LangFamily == "zh-Hant" {
	[圖]
} else if LangFamily == "zh-Hans" or TypstLang == "zh" {
	[图]
} else if TypstLang == "en" {
	[Figure]
} else {
	auto
}
#let TableSupplement = if LangFamily == "zh-Hant" or LangFamily == "zh-Hans" or TypstLang == "zh" {
	[表]
} else if TypstLang == "en" {
	[Table]
} else {
	auto
}
#let FigureKindSupplement(Kind) = {
	if Kind == table {
		TableSupplement
	} else {
		FigureSupplement
	}
}
#let FigureKindText(Kind) = {
	if Kind == table {
		if LangFamily == "zh-Hant" or LangFamily == "zh-Hans" or TypstLang == "zh" {
			"表"
		} else if TypstLang == "en" {
			"Table"
		} else {
			"Table"
		}
	} else if LangFamily == "zh-Hant" {
		"圖"
	} else if LangFamily == "zh-Hans" or TypstLang == "zh" {
		"图"
	} else if TypstLang == "en" {
		"Figure"
	} else {
		"Figure"
	}
}

#let CjkStroke_Regular = 0.030em
#let CjkStroke_Bold = 0.015em
#let CjkChars = "[\p{script=Han}！-･〇-〰—]+"


#let Todo(Title, Body) = {
	text(yellow)[#U(Title)]
	linebreak()
	Body
}

// HTML 不直接寫死相對路徑；先把項目內資產路徑放入 class，交給 Mvn.csx 解析。
#let HtmlAssetMarkerPrefix = "mvn-img-asset-"
// BasePath 僅供 PDF image(...) 使用；HtmlBase 是項目根目錄下的資產路徑。
#let FnImgGen(BasePath, HtmlBase: "assets/") = {
	let affix = ".gen.png"
	return Name => {
		if Target == TargetHtml {
			html.elem("img", attrs: (
				class: HtmlAssetMarkerPrefix + HtmlBase + Name + affix,
				alt: Name,
			))
		} else {
			image(BasePath + Name + affix)
		}
	}
}

// 普通項目圖片。Base 是 PDF 模式相對於本公共文件的路徑，HTML 只保留 Path marker。
#let ImgPath(Path, Base: ".", alt: none) = {
	if Target == TargetHtml {
		html.elem("img", attrs: (
			class: HtmlAssetMarkerPrefix + Path,
			alt: if alt == none { Path } else { alt },
		))
	} else {
		image(Base + "/" + Path)
	}
}
///
///
/// - C ():
/// ->
#let DocTitle(C) = {
	set align(center)
	set text(size: 1.5em)
	C
}


#let _Document(
	path,
	format: auto,
	title: none,
	author: (), //str[]
	description: none,
	keywords: (), //str[]
	date: auto,
	body,
) = {
	if IsBundle {
		document(
			path,
			format: format,
			title: title,
			author: author,
			description: description,
			keywords: keywords,
			date: date,
		)[#body]
	} else {
		body
	}
}

#let ColorFore = white
#let ColorBack = black
#let ColorCodeBack = rgb("#202020")
#let ColorRef = rgb("#3B82F6")
//#let BaseStroke = 0.05em
#let HtmlDocument(body) = [
	#html.elem("article", attrs: (class: "mvn-article"))[#body]
]

#let _Show(d) = {
	let PageHeight = if Target == TargetHtml {
		auto
	}else {
		841.89pt
	}
	
	set page(
		margin: 1em,
		fill: ColorBack,
		height: PageHeight,
	)

	let Styled = {
		set text(lang: TypstLang)
		show figure: set figure(
			supplement: FigureKindSupplement,
			//placement: 
		)
		// figure 保留各自的 kind，
		// 但圖注與引用都使用同一個全局 figure 計數器。
		show figure.caption: it => context {
			let Number = counter(figure).at(it.location()).first()
			let Caption = [
				#(FigureKindText(it.kind) + str(Number) + it.separator)
				#it.body
			]

			if Target == TargetHtml {
				html.elem("figcaption")[#Caption]
			} else {
				Caption
			}
		}
		show ref: it => context {
			let Target = it.element
			if Target != none and Target.func() == figure {
				let Number = counter(figure).at(Target.location()).first()
				let Label = FigureKindText(Target.kind) + str(Number)
				box[
					#link(Target.location())[
						#underline(stroke: ColorRef+0.1em)[#Label]
					]
				]
			} else {
				box[
					#underline(stroke: ColorRef)[#it]
				]
			}
		}
		show title: set align(center)
		let ShowCjkTypography(body) = {
			show regex(CjkChars): set text(font: "Noto Serif SC")// Times New Roman
			show: show-cn-fakebold
			show: show-cn-fakeitalic
			show text.where(weight: "regular"): it => regex-fakebold(
				//reg-exp: CjkChars,
				stroke: CjkStroke_Regular,
				weight: "regular",
				it,
			)
			
			show text.where(weight: "bold"): it => regex-fakebold(
				reg-exp: CjkChars,
				stroke: CjkStroke_Bold,
				weight: "bold",
				it,
			)
			body
		}

		show: ShowCjkTypography

		set text(
			size: 1.5em,
			//stroke: 0.02em + ColorFore,
			ColorFore,
			//font: "Consolas",
			//stroke: BaseStroke
		)
		
		// token 配色: VSCode Dark Modern 主題，移植自
		// dark_vs + dark_plus + 用戶 tokenColorCustomizations，
		// 詳見 DarkModern.tmTheme。
		// 無 lang 的 raw 不經高亮，仍走下方青色兜底。
		//set raw(theme: "DarkModern.tmTheme")
		
		show raw: set text(
			font: ("Consolas", "Noto Serif SC"),
			//fill: rgb("00ffff")
		)
		show raw.where(block: true): it => block(
			width: 100%,
			fill: ColorCodeBack,
			inset: 0.75em,
		)[#it]
		show raw: it => context {
			let ParentFill = text.fill
			set text(
				font: "Consolas",
				fill: if ParentFill == ColorFore {
					rgb("00ffff")
				} else {
					ParentFill
				},
			)
			it
		}
		set table(
			stroke: ColorFore,
		)
		set heading(numbering: numbly(
			"{1:1} |",
			"{1}.{2} |", // use {level:format} to specify the format
			"{1}.{2}.{3} |",
			"{1}.{2}.{3}.{4} |",
			"{1}.{2}.{3}.{4}.{5} |",
		))
		d
	}

	if Target == TargetHtml {
		HtmlDocument(Styled)
	} else {
		Styled
	}
}
