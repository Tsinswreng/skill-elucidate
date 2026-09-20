#import "@preview/tsinswreng-auto-heading:0.1.0": auto-heading
#import "@preview/cuti:0.4.0": regex-fakebold, show-cn-fakebold, show-cn-fakeitalic
#import "@preview/numbly:0.1.0": numbly
#let tsinswreng-heading-level = state("tsinswreng-heading-level", 0)

// 自動層級標題。帶命名參數時要用圓括號，如 #H(level: 3)[題][文]。
// - level：本標題的絕對層級，默認在當前層級上加一；
//   子孫在此之上繼續嵌套，本子樹結束後恢復原層級。
// - start：本標題的序號（末位數字），默認接着計數；
//   如 start: 2 則本標題顯示 2.、子標題顯示 2.1。
// - label：附着到本標題的 label 值（如 <sec>），之後用 @sec 引用。
// 有bug, 序列與層級會亂變。已廢棄
// #let auto-heading(title, content, level: none, start: none, label: none) = context {
// 	let outer = tsinswreng-heading-level.get()
// 	let lvl = if level == none { outer + 1 } else { level }
// 	tsinswreng-heading-level.update(_ => lvl)
// 	if start != none {
// 		// 先把編號計數器撥到 start 的前一個數，
// 		// 下面 heading 出現時自增一位，從而顯示 start。
// 		// 父鏈照舊；比當前深度更深時中間層補 0（與手寫跳層行爲一致）。
// 		let before = counter(heading).get()
// 		let prefix = range(lvl - 1).map(i => if i < before.len() { before.at(i) } else { 0 })
// 		counter(heading).update(prefix + (start - 1,))
// 	}
// 	[#heading(level: lvl)[#title] #label]

// 	content

// 	tsinswreng-heading-level.update(_ => outer)
// }

#let H = auto-heading
#let P(C) = {
	h(2em)
	C
}
#let U(C) = {
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
	text(red)[#U(Title)]
	linebreak()
	box(fill: rgb("#550000"))[#Body]
}

#let Wip(Title, Body) = {
	text(yellow)[#U(Title)]
	linebreak()
	box(fill: rgb("#555500"))[#Body]
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
#let ColorCodeBack = rgb("#002020")
// 代碼塊／引用塊的邊框：顏色比底色亮一階，粗細單獨控制；HTML 與 PDF 共用此二值。
#let ColorCodeBorder = rgb("#006060")
#let StrokeCodeBorder = 1pt
#let ColorRef = rgb("#3B82F6")
//#let BaseStroke = 0.05em
#let HtmlDocument(body) = [
	#html.elem("article", attrs: (class: "mvn-article"))[#body]
]

#let _Show(d) = {
	let PageHeight = if Target == TargetHtml {
		auto
	} else {
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
						#underline(stroke: ColorRef + 0.1em)[#Label]
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
			show regex(CjkChars): set text(font: "Noto Serif SC") // Times New Roman
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
		// 主題默認色等於環境色的 token 不帶 span，
		// 普通文本因此落到下方兜底規則：
		// 塊級代碼（含無 lang 者）跟正文同白，行內代碼保持青色。
		//set raw(theme: "DarkModern.tmTheme")

		show raw: set text(
			font: ("Consolas", "Noto Serif SC"),
			//fill: rgb("00ffff")
		)
		show raw.where(block: true): it => {
			if Target == TargetHtml {
				// HTML 導出不翻譯 block 的 fill/stroke，故直接輸出帶樣式的 div 包住 pre。
				html.elem("div", attrs: (
					style: "background:" + ColorCodeBack.to-hex()
						+ ";border:" + repr(StrokeCodeBorder) + " solid " + ColorCodeBorder.to-hex()
						+ ";border-radius:2pt;padding:0.75em;",
				))[
					#box(width: 100%)[#it]
				]
			} else {
				block(
					width: 100%,
					fill: ColorCodeBack,
					stroke: StrokeCodeBorder + ColorCodeBorder,
					inset: 0.75em,
					//radius: 2pt,
				)[#it]
			}
		}
		show raw: it => context {
			let ParentFill = text.fill
			set text(
				font: "Consolas",
				fill: if ParentFill != ColorFore {
					// 嵌套在有色環境（如 Todo）內時跟隨環境色。
					ParentFill
				} else if it.block {
					// 塊級代碼（含無 lang 者）普通文本跟正文同白。
					ColorFore
				} else {
					// 行內代碼保持青色。
					rgb("00ffff")
				},
			)
			it
		}
		// 引用塊：與多行代碼塊同底色、同邊框。
		// HTML 導出不翻譯 block 的 fill/stroke，分靶處理。
		show quote.where(block: true): it => {
			if Target == TargetHtml {
				html.elem("div", attrs: (
					style: "background:" + ColorCodeBack.to-hex()
						+ ";border:" + repr(StrokeCodeBorder) + " solid " + ColorCodeBorder.to-hex()
						+ ";border-radius:2pt;padding:0.75em;white-space:pre-wrap;",
				))[#it.body]
			} else {
				block(
					width: 100%,
					fill: ColorCodeBack,
					stroke: StrokeCodeBorder + ColorCodeBorder,
					inset: 0.75em,
					//radius: 2pt,
					breakable: true,
					it.body,
				)
			}
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
