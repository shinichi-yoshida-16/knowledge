# Apache POIによるExcel出力(Spring Boot拡張)

## 1. 目的・概要
### 1.1 本資料の目的
- [spring_boot.md](./spring_boot.md)で整理したSpring Bootアプリケーションに対する拡張トピックとして、Apache POIを用いたExcelファイル出力の仕様・導入手順・ベストプラクティスを整理する
- 対象は「Excel出力(サーバ側でExcelファイルを生成し、クライアントにダウンロード提供する)」を中心とする

### 1.2 前提
- [spring_boot.md](./spring_boot.md)の3節で作成したSpring Bootプロジェクト(Java 17+、Maven)への追加を前提とする
- Apache POIバージョンは5.x系(執筆時点の目安: 5.3系)を前提とする。導入時は[Maven Central](https://mvnrepository.com/artifact/org.apache.poi/poi-ooxml)で最新の安定版を確認する

## 2. Apache POIとは
### 2.1 概要
- Javaから Microsoft Office形式(Excel/Word/PowerPoint)のファイルを読み書きするためのApache製オープンソースライブラリ
- Excel関連では、旧形式(.xls, バイナリ形式)向けの`HSSF`、新形式(.xlsx, OOXML/ZIP形式)向けの`XSSF`、大量データ出力向けの省メモリ実装`SXSSF`を提供する
- 参考資料
  - https://poi.apache.org/
  - https://poi.apache.org/components/spreadsheet/

### 2.2 主要パッケージ・クラス比較表
| 実装 | 対応形式 | 特徴 | 主な用途 |
|---|---|---|---|
| HSSF | .xls(Excel 97-2003、バイナリ形式) | 行数上限65,536行。レガシー形式 | 旧システムとの互換が必要な場合のみ |
| XSSF | .xlsx(Excel 2007以降、OOXML/ZIP形式) | 全データをメモリ上に保持するため大量データ出力ではメモリ消費が大きい | 標準的なExcel出力(数千行程度まで) |
| SXSSF | .xlsx(XSSFのストリーミング版) | 指定した行数(ウィンドウ)のみメモリ保持し、古い行はディスクへフラッシュ | 数万行以上の大量データ出力 |

- 依存モジュールの対応関係
  - `poi`: HSSF(.xls)およびPOI共通クラスを含む基本モジュール
  - `poi-ooxml`: XSSF/SXSSF(.xlsx)を扱うために必要な追加モジュール(`poi`に依存)

## 3. Spring Bootへの導入
### 3.1 依存関係の追加(Maven)
```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi</artifactId>
    <version>5.3.0</version>
</dependency>
<dependency>
    <groupId>org.apache.poi</groupId>
    <artifactId>poi-ooxml</artifactId>
    <version>5.3.0</version>
</dependency>
```
- Gradleの場合
  ```groovy
  // build.gradle
  implementation 'org.apache.poi:poi:5.3.0'
  implementation 'org.apache.poi:poi-ooxml:5.3.0'
  ```
- `.xlsx`(OOXML形式)のみを扱う場合でも、内部的に`poi`本体への依存が必要なため両方を追加する

### 3.2 プロジェクト構成
```
demo
└── src/main/java/com/example/demo
    ├── controller
    │   └── ItemExportController.java   # ダウンロードエンドポイント
    └── excel
        └── ItemExcelExporter.java      # Excel生成ロジック(POI操作を集約)
```
- POI操作(セル/行/シートの直接操作)はController・Serviceに混在させず、専用クラス(Exporter/Writer等)に集約する(7節のベストプラクティス参照)

## 4. チュートリアル: Excel出力APIの作成
### 4.1 データモデル・サンプルデータ準備
- [spring_boot.md](./spring_boot.md) 3.4節の`Item`エンティティ・`ItemService`を利用する前提とする

### 4.2 Excel生成サービスの実装
```java
// excel/ItemExcelExporter.java
package com.example.demo.excel;

import com.example.demo.domain.Item;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

@Component
public class ItemExcelExporter {

    private static final String[] HEADERS = {"ID", "商品名", "価格"};

    public byte[] export(List<Item> items) {
        // try-with-resourcesでWorkbookを確実にクローズする(7.1節参照)
        try (Workbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {

            Sheet sheet = workbook.createSheet("商品一覧");
            CellStyle headerStyle = createHeaderStyle(workbook);

            writeHeaderRow(sheet, headerStyle);
            writeDataRows(sheet, items);

            for (int i = 0; i < HEADERS.length; i++) {
                sheet.autoSizeColumn(i); // 列幅自動調整(件数が多い場合は7.3節参照)
            }

            workbook.write(out);
            return out.toByteArray();
        } catch (IOException e) {
            throw new IllegalStateException("Excel出力に失敗しました", e);
        }
    }

    private void writeHeaderRow(Sheet sheet, CellStyle headerStyle) {
        Row headerRow = sheet.createRow(0);
        for (int i = 0; i < HEADERS.length; i++) {
            Cell cell = headerRow.createCell(i);
            cell.setCellValue(HEADERS[i]);
            cell.setCellStyle(headerStyle);
        }
    }

    private void writeDataRows(Sheet sheet, List<Item> items) {
        int rowNo = 1;
        for (Item item : items) {
            Row row = sheet.createRow(rowNo++);
            row.createCell(0).setCellValue(item.getId());
            row.createCell(1).setCellValue(item.getName());
            row.createCell(2).setCellValue(item.getPrice());
        }
    }

    private CellStyle createHeaderStyle(Workbook workbook) {
        // セルスタイルはWorkbookごとに使い回す(7.2節参照。行/セル単位で毎回生成しない)
        CellStyle style = workbook.createCellStyle();
        Font font = workbook.createFont();
        font.setBold(true);
        style.setFont(font);
        style.setFillForegroundColor(IndexedColors.GREY_25_PERCENT.getIndex());
        style.setFillPattern(FillPatternType.SOLID_FOREGROUND);
        return style;
    }
}
```

### 4.3 Controllerからのダウンロード提供
```java
// controller/ItemExportController.java
package com.example.demo.controller;

import com.example.demo.excel.ItemExcelExporter;
import com.example.demo.service.ItemService;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/api/items")
public class ItemExportController {
    private final ItemService itemService;
    private final ItemExcelExporter exporter;

    public ItemExportController(ItemService itemService, ItemExcelExporter exporter) {
        this.itemService = itemService;
        this.exporter = exporter;
    }

    @GetMapping("/export")
    public ResponseEntity<byte[]> exportExcel() {
        byte[] excelBytes = exporter.export(itemService.findAll());

        String filename = "items.xlsx";
        String encodedFilename = java.net.URLEncoder.encode(filename, StandardCharsets.UTF_8);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType(
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
        // 日本語ファイル名対策としてfilename*(RFC 5987形式)を併記する(7.4節参照)
        headers.setContentDisposition(ContentDisposition.attachment()
                .filename(filename, StandardCharsets.UTF_8)
                .build());

        return ResponseEntity.ok().headers(headers).body(excelBytes);
    }
}
```

### 4.4 動作確認
- > curl -o items.xlsx http://localhost:8080/api/items/export
- ダウンロードした`items.xlsx`をExcel(またはLibreOffice Calc)で開き、ヘッダー行・データ行・スタイルが反映されていることを確認する

## 5. 応用: 大量データ出力(SXSSFによるストリーミング)
- 数万行規模のデータを出力する場合、`XSSFWorkbook`は全行をメモリ上に保持するためOutOfMemoryErrorのリスクがある。`SXSSFWorkbook`を用いてメモリ上に保持する行数(ウィンドウサイズ)を制限する
```java
import org.apache.poi.xssf.streaming.SXSSFWorkbook;

public byte[] exportLarge(List<Item> items) {
    // 引数はメモリ保持する行数。超えた古い行は自動的に一時ファイルへフラッシュされる
    try (SXSSFWorkbook workbook = new SXSSFWorkbook(100);
         ByteArrayOutputStream out = new ByteArrayOutputStream()) {

        workbook.setCompressTempFiles(true); // 一時ファイルを圧縮してディスク消費を抑える
        Sheet sheet = workbook.createSheet("商品一覧");
        // ...ヘッダー・データ行の書き込みは4.2節と同様...

        workbook.write(out);
        workbook.dispose(); // SXSSF使用時は一時ファイルの明示的な削除が必須
        return out.toByteArray();
    } catch (IOException e) {
        throw new IllegalStateException("Excel出力に失敗しました", e);
    }
}
```
- SXSSFでは書き込み済みの行に対して`autoSizeColumn`等の再アクセスができない(すでにフラッシュされているため)。列幅は固定値(`sheet.setColumnWidth(...)`)で指定するか、出力前に別途集計しておく
- HTTPレスポンスとして返す場合も、`byte[]`に一度全展開するのではなく`StreamingResponseBody`を用いて`OutputStream`に直接書き込むと、サーバ側のメモリ消費をさらに抑えられる
  ```java
  @GetMapping("/export-large")
  public ResponseEntity<StreamingResponseBody> exportLarge() {
      StreamingResponseBody body = outputStream -> {
          try (SXSSFWorkbook workbook = new SXSSFWorkbook(100)) {
              // ...書き込み処理...
              workbook.write(outputStream);
              workbook.dispose();
          }
      };
      return ResponseEntity.ok()
              .contentType(MediaType.parseMediaType(
                      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
              .body(body);
  }
  ```

## 6. 応用: テンプレートファイルを利用した出力
- 罫線・書式・ロゴ等が予め設定された既存のExcelテンプレート(`.xlsx`)を`classpath:templates/`等に配置し、それを読み込んでセル値のみ差し替えて出力する方法もよく使われる(帳票出力等)
```java
try (InputStream is = getClass().getResourceAsStream("/templates/item_template.xlsx");
     Workbook workbook = new XSSFWorkbook(is);
     ByteArrayOutputStream out = new ByteArrayOutputStream()) {

    Sheet sheet = workbook.getSheetAt(0);
    Row row = sheet.getRow(1); // テンプレート側で用意した書き込み対象行
    row.getCell(0).setCellValue("値");

    workbook.write(out);
}
```
- テンプレート方式は、複雑な書式(セル結合、印刷設定、条件付き書式等)をPOIのコードで再現する手間を省ける利点がある一方、テンプレートファイルのレイアウト変更に出力コードが追従できているかのテストが重要になる

## 7. ベストプラクティス
### 7.1 ワークブック/リソース管理(try-with-resources)
- `Workbook`(および読み込み時の`InputStream`)は必ず`try-with-resources`でクローズする。特に`SXSSFWorkbook`はクローズ漏れがあると一時ファイルがディスクに残り続ける
- `SXSSFWorkbook`使用時は`close()`に加えて`dispose()`を呼び、一時ファイルを明示的に削除する

### 7.2 セルスタイルの再利用
- `CellStyle`/`Font`はセル・行ごとに生成せず、Workbookあたり必要なパターン数だけ生成して使い回す
  - 理由: Excel(OOXML)の内部仕様上、スタイルはWorkbook内で共有される定義であり、セル単位で毎回`createCellStyle()`すると数千・数万件規模でスタイル定義が肥大化し、生成時間とファイルサイズの両方が悪化する

### 7.3 大量データ時のメモリ対策(SXSSF、ウィンドウサイズ)
- 数千行程度まではXSSFで十分だが、数万行を超える・実行環境のメモリが限られる場合はSXSSFを使う(5節参照)
- `autoSizeColumn`は全セルを走査するため行数が多いと非常に遅い。大量データでは列幅を固定値指定に切り替える、またはヘッダー行のみでサンプリングする等の代替を検討する
- Webアプリでは大量データのExcel出力はリクエスト同期処理ではなく非同期化(ジョブ化してファイル生成後に通知/ダウンロードリンク発行)する設計も検討する(7.5節参照)

### 7.4 ファイル名・Content-Type・文字エンコーディング
- Content-Typeは`.xlsx`の場合`application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`、`.xls`の場合`application/vnd.ms-excel`を指定する
- ダウンロードファイル名に日本語を含める場合、`Content-Disposition`ヘッダーの`filename*=UTF-8''...`(RFC 5987形式)を使うか、Spring の`ContentDisposition.attachment().filename(name, StandardCharsets.UTF_8)`を利用してブラウザ間の文字化けを防ぐ
- セル内の文字列は基本的にJavaの`String`(UTF-16)のまま扱えばよく、POI側で追加のエンコーディング指定は不要

### 7.5 非同期化・タイムアウト対策
- 大量データ出力はDB取得〜Excel生成〜レスポンス送信までの時間がHTTPタイムアウトを超えるリスクがある。件数が多い出力機能は以下のいずれかを検討する
  - `StreamingResponseBody`でレスポンスをストリーミングし、生成しながら送出する(5節参照)
  - 非同期ジョブとして実行し、完了後にファイルダウンロード用のURLを別途提供する(`@Async`やジョブキュー、Spring Batch等と組み合わせる)

### 7.6 テスト方法
- 生成した`byte[]`をPOIで再読み込みし、シート名・ヘッダー・値をアサートすることでExcel出力ロジックを自動テストできる
  ```java
  @Test
  void export_containsHeaderAndRows() throws IOException {
      byte[] bytes = exporter.export(List.of(new Item(1L, "pen", 100)));
      try (Workbook wb = WorkbookFactory.create(new ByteArrayInputStream(bytes))) {
          Sheet sheet = wb.getSheetAt(0);
          assertThat(sheet.getRow(0).getCell(0).getStringCellValue()).isEqualTo("ID");
          assertThat(sheet.getRow(1).getCell(1).getStringCellValue()).isEqualTo("pen");
      }
  }
  ```
- `WorkbookFactory.create(InputStream)`は拡張子に関わらず.xls/.xlsxを自動判別して読み込めるため、テストや汎用の読み込み処理で便利

### 7.7 バージョン管理・依存関係の注意点
- `poi`と`poi-ooxml`は必ず同一バージョンで揃える(バージョン不一致によるクラス不整合の実行時エラーを防ぐため)。Spring Boot BOM管理下にない依存のため、バージョンは明示的にpom.xml/build.gradleで固定する
- POIは内部でXMLパーサ(Apache Commons Compress、XMLBeans等)に依存するため、脆弱性対応のバージョンアップ時はこれらの推移的依存も含めて`mvn dependency:tree`等で確認する
- 大きな`.xlsx`ファイルを読み込む場合、ZIP展開後のデータ膨張によるメモリ枯渇("Zip bomb")対策として、POIの`ZipSecureFile.setMinInflateRatio(...)`等の閾値設定が用意されている点も、外部アップロードファイルを扱う機能では留意する

## 8. 用語・注意点まとめ
- OOXML(Office Open XML): .xlsx/.docx/.pptx等で使われる、ZIP形式でXMLファイル群をまとめたOffice文書のオープン標準フォーマット
- HSSF/XSSF/SXSSF: それぞれ旧バイナリ形式(.xls)、新形式(.xlsx)、新形式のストリーミング(省メモリ)実装を指すPOIのAPI名称
- ウィンドウサイズ(SXSSF): メモリ上に保持する行数の上限。これを超えると古い行から順にディスク上の一時ファイルへ書き出される
- `dispose()`: SXSSFWorkbookが使用した一時ファイルを削除するためのメソッド。呼び忘れるとディスクに一時ファイルが残り続ける
- 本資料はExcel「出力」を中心に扱った。Excelファイルの「読み込み(アップロード・インポート)」も業務要件として発生しやすいため、必要に応じて別途ナレッジ化を検討する
