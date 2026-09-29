# Java Spring / Spring Boot 言語仕様・チュートリアル・ベストプラクティス

## 1. 目的・概要
### 1.1 本資料の目的
- Java向けの主要フレームワークであるSpring Framework / Spring Bootについて、仕様概要・導入手順・利用用途を整理し、開発・選定時の指針とする
- Excel出力等の拡張トピックは、本資料から分離し[apache_poi_excel.md](./apache_poi_excel.md)にまとめる

### 1.2 前提
- Java 17以上(LTS版)を前提とする(Spring Boot 3.x系はJava 17が最低要件)
- ビルドツールはMaven/Gradleいずれでも可(本資料はMavenを主に例示する)
- 本資料執筆時点の目安バージョン: Spring Boot 3.3系、Java 17〜21。実際の導入時は[Spring Initializr](https://start.spring.io/)で最新の安定版を確認する

## 2. Spring / Spring Boot とは
### 2.1 Spring Framework
- Javaアプリケーション開発向けの基盤フレームワーク。DI(依存性注入)コンテナを中核に、AOP・トランザクション管理・Web MVC・データアクセス抽象化等、エンタープライズ開発に必要な機能群を提供する
- 「POJO(Plain Old Java Object)をフレームワークに縛られずに書き、フレームワーク側が結線・横断的関心事を担う」という設計思想が特徴
- 参考資料
  - https://spring.io/projects/spring-framework
  - https://docs.spring.io/spring-framework/reference/

### 2.2 Spring Boot
- Spring Frameworkをベースに、「設定より規約(Convention over Configuration)」の思想で開発を高速化するフレームワーク
- 自動設定(Auto Configuration)・組み込みApサーバ(Tomcat等)・スターター依存関係(Starter)により、XML設定やサーバへのデプロイ作業を大幅に削減する
- 単体で実行可能なjar(Fat Jar/Executable Jar)を生成できるため、コンテナ化(Docker)やクラウド環境への配備が容易
- 参考資料
  - https://spring.io/projects/spring-boot
  - https://docs.spring.io/spring-boot/reference/

### 2.3 Spring FrameworkとSpring Bootの関係比較表
| 項目 | Spring Framework | Spring Boot |
|---|---|---|
| 位置づけ | 基盤フレームワーク(DI/AOP/MVC等) | Spring Frameworkを土台にした「開発を早くする仕組み」 |
| 設定方法 | 明示的な設定(XML/JavaConfigでBean定義等)が基本 | 自動設定(Auto Configuration)により大部分が省略可能 |
| サーバ | 別途Webサーバ(Tomcat等)へWARを配備するのが一般的 | 組み込みサーバ(Tomcat/Jetty/Undertow)を内包し単体起動可能 |
| 依存管理 | 個々の依存を手動で選定・バージョン管理 | Starter依存(`spring-boot-starter-*`)とBOMによる一括管理 |
| 学習コスト | 中〜高(仕組みを理解して明示的に設定) | 低〜中(規約に従えば最小構成で開発開始できる) |
| 主な用途 | Spring Bootの内部でも利用される基盤。既存の大規模Springアプリの保守等 | 新規のWebアプリ・REST API・マイクロサービス開発の第一選択 |

## 3. 環境構築・チュートリアル
### 3.1 前提環境
- JDK 17以上、Maven 3.9以上(または同梱の`mvnw`)、任意のIDE(IntelliJ IDEA/VS Code等)

### 3.2 プロジェクトの作成(Spring Initializr)
- https://start.spring.io/ にアクセスし、以下を選択して生成
  - Project: Maven
  - Language: Java
  - Spring Boot: 最新の安定版(3.x系)
  - Dependencies: `Spring Web`、`Spring Data JPA`、`Validation`、`H2 Database`(学習用インメモリDB)、`Spring Boot DevTools`
- ZIPをダウンロードして展開、またはCLIで取得
  - > curl https://start.spring.io/starter.zip -d dependencies=web,data-jpa,validation,h2,devtools -d javaVersion=17 -o demo.zip

### 3.3 プロジェクト構成
```
demo
├── pom.xml
└── src
    ├── main
    │   ├── java/com/example/demo
    │   │   ├── DemoApplication.java     # エントリポイント(@SpringBootApplication)
    │   │   ├── controller                # Webレイヤー(@RestController)
    │   │   ├── service                   # 業務ロジック層(@Service)
    │   │   ├── repository                # データアクセス層(@Repository)
    │   │   ├── domain / entity           # エンティティ・ドメインモデル
    │   │   └── dto                       # リクエスト/レスポンス用DTO
    │   └── resources
    │       ├── application.yml
    │       └── static / templates
    └── test
        └── java/com/example/demo
```

### 3.4 最小構成アプリの作成(REST API)
- エントリポイント
  ```java
  // src/main/java/com/example/demo/DemoApplication.java
  package com.example.demo;

  import org.springframework.boot.SpringApplication;
  import org.springframework.boot.autoconfigure.SpringBootApplication;

  @SpringBootApplication
  public class DemoApplication {
      public static void main(String[] args) {
          SpringApplication.run(DemoApplication.class, args);
      }
  }
  ```
- エンティティ
  ```java
  // domain/Item.java
  package com.example.demo.domain;

  import jakarta.persistence.Entity;
  import jakarta.persistence.GeneratedValue;
  import jakarta.persistence.GenerationType;
  import jakarta.persistence.Id;

  @Entity
  public class Item {
      @Id
      @GeneratedValue(strategy = GenerationType.IDENTITY)
      private Long id;
      private String name;
      private Integer price;

      // getter/setterは省略(Lombokの@Getter/@Setterでも代替可、6.2節参照)
  }
  ```
- リポジトリ
  ```java
  // repository/ItemRepository.java
  package com.example.demo.repository;

  import com.example.demo.domain.Item;
  import org.springframework.data.jpa.repository.JpaRepository;

  public interface ItemRepository extends JpaRepository<Item, Long> {
  }
  ```
- サービス
  ```java
  // service/ItemService.java
  package com.example.demo.service;

  import com.example.demo.domain.Item;
  import com.example.demo.repository.ItemRepository;
  import org.springframework.stereotype.Service;
  import java.util.List;

  @Service
  public class ItemService {
      private final ItemRepository itemRepository;

      // コンストラクタインジェクション(6.1節のベストプラクティス参照)
      public ItemService(ItemRepository itemRepository) {
          this.itemRepository = itemRepository;
      }

      public List<Item> findAll() {
          return itemRepository.findAll();
      }

      public Item save(Item item) {
          return itemRepository.save(item);
      }
  }
  ```
- コントローラ
  ```java
  // controller/ItemController.java
  package com.example.demo.controller;

  import com.example.demo.domain.Item;
  import com.example.demo.service.ItemService;
  import org.springframework.web.bind.annotation.*;
  import java.util.List;

  @RestController
  @RequestMapping("/api/items")
  public class ItemController {
      private final ItemService itemService;

      public ItemController(ItemService itemService) {
          this.itemService = itemService;
      }

      @GetMapping
      public List<Item> list() {
          return itemService.findAll();
      }

      @PostMapping
      public Item create(@RequestBody Item item) {
          return itemService.save(item);
      }
  }
  ```
- 設定ファイル(H2利用時)
  ```yaml
  # src/main/resources/application.yml
  spring:
    datasource:
      url: jdbc:h2:mem:demo
    jpa:
      hibernate:
        ddl-auto: update
    h2:
      console:
        enabled: true   # http://localhost:8080/h2-console でDB確認可能
  ```

### 3.5 アプリケーションの起動
- > ./mvnw spring-boot:run    # WindowsはmvnwのままPowerShellでも実行可
- 起動後、以下でAPI動作確認
  - > curl -X POST http://localhost:8080/api/items -H "Content-Type: application/json" -d "{\"name\":\"pen\",\"price\":100}"
  - > curl http://localhost:8080/api/items

### 3.6 ビルド・パッケージング
- 実行可能jarの作成
  - > ./mvnw clean package
  - `target/demo-0.0.1-SNAPSHOT.jar`が生成される(組み込みTomcatを含む単体実行可能jar)
- 実行
  - > java -jar target/demo-0.0.1-SNAPSHOT.jar

## 4. Spring Boot の主要機能・仕様
### 4.1 DI(依存性注入)とIoCコンテナ
- Spring本体の中核機能。オブジェクト(Bean)の生成・依存関係の解決をコンテナ(ApplicationContext)が担い、開発者はコンストラクタ等でその依存を「受け取る」だけでよい(制御の反転、IoC)
- インジェクション方式は主に3種類あるが、コンストラクタインジェクションが推奨される(6.1節参照)

### 4.2 Bean定義とコンポーネントスキャン
- `@Component`(および`@Service`/`@Repository`/`@Controller`/`@RestController`等の派生アノテーション)を付与したクラスは、`@SpringBootApplication`配下のパッケージスキャンにより自動的にBean登録される
- 明示的にBeanを定義したい場合は`@Configuration`クラス内で`@Bean`メソッドを用いる
  ```java
  @Configuration
  public class AppConfig {
      @Bean
      public RestTemplate restTemplate() {
          return new RestTemplate();
      }
  }
  ```

### 4.3 自動設定(Auto Configuration)とスターター
- クラスパス上の依存(例: `spring-boot-starter-data-jpa`が存在すればJPA関連のBeanを自動構成)や設定値に応じて、`@Conditional`系アノテーションを用いた条件分岐でBeanを自動登録する仕組み
- スターター(`spring-boot-starter-web`、`spring-boot-starter-data-jpa`等)は、関連ライブラリと互換バージョンをまとめて導入できる依存パッケージ
- 自動設定の内容は`--debug`起動オプション、または`ConditionEvaluationReport`で確認できる

### 4.4 設定ファイル(application.yml/properties)とプロファイル
- `application.yml`(または`.properties`)に接続情報・各種パラメータを外部化する
- 環境別設定は`application-{profile}.yml`を用意し、`spring.profiles.active`で切り替える
  - > java -jar app.jar --spring.profiles.active=prod
- 型安全に設定値を扱いたい場合は`@ConfigurationProperties`を用いる
  ```java
  @ConfigurationProperties(prefix = "app.mail")
  public record MailProperties(String host, int port) {}
  ```

### 4.5 レイヤードアーキテクチャ(Controller/Service/Repository)
- Web層(`@RestController`)→業務層(`@Service`)→データアクセス層(`@Repository`)の3層構成が基本パターン
- Controllerはリクエスト/レスポンスの変換(DTO⇔ドメイン)とルーティングに専念し、業務ロジックはServiceに集約する

### 4.6 Spring Data JPAによるデータアクセス
- `JpaRepository<Entity, ID>`を継承するだけでCRUDメソッド(`findAll`/`findById`/`save`/`deleteById`等)が自動実装される
- メソッド名からクエリを自動生成するクエリメソッド(例: `findByNameContaining(String name)`)、複雑な条件は`@Query`でJPQL/ネイティブSQLを記述
- ページング・ソートは`Pageable`/`Page<T>`で対応

### 4.7 バリデーション
- Bean Validation(`jakarta.validation`)のアノテーション(`@NotNull`/`@Size`/`@Email`等)をDTOに付与し、Controller引数に`@Valid`を付けることで自動検証される
  ```java
  public record ItemRequest(@NotBlank String name, @Min(0) Integer price) {}

  @PostMapping
  public Item create(@Valid @RequestBody ItemRequest req) { ... }
  ```

### 4.8 例外処理(@ControllerAdvice)
- `@RestControllerAdvice`クラスで例外を横断的にハンドリングし、統一されたエラーレスポンス形式(例: RFC 9457 Problem Details)を返す
  ```java
  @RestControllerAdvice
  public class GlobalExceptionHandler {
      @ExceptionHandler(MethodArgumentNotValidException.class)
      public ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException ex) {
          ProblemDetail pd = ProblemDetail.forStatus(HttpStatus.BAD_REQUEST);
          pd.setDetail(ex.getMessage());
          return ResponseEntity.badRequest().body(pd);
      }
  }
  ```

### 4.9 AOP(アスペクト指向プログラミング)
- ログ出力・トランザクション・監査等の横断的関心事を、業務ロジックから分離して実装する仕組み
- `@Aspect`+`@Around`等のアドバイスでメソッド呼び出しをインターセプトする。`@Transactional`もAOPの仕組み上で実現されている

### 4.10 Spring Boot Actuator
- 依存: `spring-boot-starter-actuator`
- `/actuator/health`、`/actuator/metrics`等のエンドポイントで、稼働監視・ヘルスチェック・メトリクス収集が可能になる。本番運用には導入必須級の機能

### 4.11 テスト(JUnit5 / MockMvc / @SpringBootTest)
- `spring-boot-starter-test`にJUnit5・Mockito・AssertJ・MockMvcが同梱される
- 単体テスト: `@ExtendWith(MockitoExtension.class)`でServiceをモック依存とともに検証
- 結合テスト: `@SpringBootTest`でApplicationContextを起動し、`@AutoConfigureMockMvc`でHTTP層を検証
  ```java
  @SpringBootTest
  @AutoConfigureMockMvc
  class ItemControllerTest {
      @Autowired MockMvc mockMvc;

      @Test
      void list_returnsOk() throws Exception {
          mockMvc.perform(get("/api/items"))
                 .andExpect(status().isOk());
      }
  }
  ```
- DBを含む結合テストは、実DBに近い環境で検証するためTestcontainers(5節参照)を用いるのが近年の主流

## 5. 主要な拡張ライブラリ
| ライブラリ | 用途 | 導入(Maven依存の`artifactId`) |
|---|---|---|
| Spring Security | 認証・認可(Basic/Form/JWT/OAuth2対応) | `spring-boot-starter-security` |
| Spring Boot Actuator | 稼働監視・ヘルスチェック・メトリクス | `spring-boot-starter-actuator` |
| Spring Cloud | マイクロサービス基盤(Config/Gateway/サービスディスカバリ等) | `spring-cloud-starter-*` |
| springdoc-openapi | OpenAPI(Swagger UI)ドキュメント自動生成 | `springdoc-openapi-starter-webmvc-ui` |
| Lombok | Getter/Setter/コンストラクタ等のボイラープレート削減 | `lombok` |
| MapStruct | Entity⇔DTO変換コードの自動生成 | `mapstruct` |
| Flyway / Liquibase | DBマイグレーション管理 | `flyway-core` / `liquibase-core` |
| Testcontainers | Dockerを用いた結合テスト用の実DB・実サービス起動 | `testcontainers` |
| Apache POI | Excelファイルの読み書き(詳細は[apache_poi_excel.md](./apache_poi_excel.md)) | `poi` / `poi-ooxml` |

## 6. ベストプラクティス
### 6.1 依存性注入
- フィールドインジェクション(`@Autowired`をフィールドに付与)は避け、コンストラクタインジェクションを用いる
  - 理由: 不変性(`final`化)の確保、必須依存の明示、テスト時にモックを注入しやすい、循環依存をコンパイル/起動時に検知しやすい
- 依存が多くなりすぎる(コンストラクタ引数が肥大化する)場合は、クラスの責務が大きすぎるサインとして分割を検討する

### 6.2 レイヤー分離とDTO
- EntityをそのままAPIのリクエスト/レスポンスに使わず、DTO(Data Transfer Object)を介して変換する
  - 理由: DB構造の変更がAPI仕様に直結することを防ぎ、公開したくないフィールドの意図しない露出(Over-fetching)を防ぐ
- DTO⇔Entityの変換はMapStruct等で自動化し、手書きの変換コードを減らす

### 6.3 設定管理
- 秘匿情報(DB接続情報、APIキー等)は`application.yml`に直接書かず、環境変数やSpring Cloud Config、Vault等の外部シークレット管理に委ねる
- 環境ごとの差異は`application-{profile}.yml`で分離し、共通設定は`application.yml`にまとめる

### 6.4 例外処理・ログ
- ビジネス例外は独自の非チェック例外クラスとして定義し、`@RestControllerAdvice`で一元的にHTTPステータス・エラーレスポンスへ変換する
- ログはSLF4J経由(`LoggerFactory.getLogger`)で出力し、`System.out.println`は使わない。本番ログはJSON等の構造化ログにしておくと運用時の検索性が上がる

### 6.5 トランザクション管理
- `@Transactional`はService層(業務ロジックの入口)に付与し、Controller層には付けない
- 読み取り専用処理には`@Transactional(readOnly = true)`を付け、不要な書き込みロックやダーティチェックを避ける
- 同一クラス内メソッド呼び出しでは`@Transactional`のAOPプロキシが効かない点に注意する(自己呼び出し問題)

### 6.6 セキュリティ
- Spring Securityを用い、パスワードは`BCryptPasswordEncoder`等でハッシュ化して保存する(平文保存は厳禁)
- REST APIではCSRF対策の要否(トークン認証中心ならCSRF保護は無効化されることが多い)とCORS設定を明示的に確認する
- 依存ライブラリの脆弱性は`mvn versions:display-dependency-updates`や`dependabot`等で定期的に確認する

### 6.7 テスト戦略
- テストピラミッドに従い、単体テスト(Service/ドメインロジック)を厚く、結合テスト(Controller〜DB)は主要シナリオに絞る
- DBアクセスを含む結合テストはH2等のインメモリDBよりも、本番と同種のDBをTestcontainersで起動して検証する方が本番差異による不具合を早期に検出できる

### 6.8 API設計
- リソース指向のURL設計(名詞+HTTPメソッド、例: `GET /api/items/{id}`)を基本とし、動詞を含むURLは避ける
- 一覧APIはページング(`Pageable`)を前提に設計し、無制限な全件取得エンドポイントを避ける
- APIドキュメントはspringdoc-openapiでコードから自動生成し、手書きドキュメントとの不整合を防ぐ

### 6.9 ビルド・運用
- 本番運用では組み込みTomcatのスレッド数・DBコネクションプール(HikariCP)のサイズをアプリの負荷特性に合わせて明示的にチューニングする
- コンテナ化する場合、Spring Boot 2.3以降標準の「レイヤードjar(Layered Jar)」機能を使い、依存ライブラリ層とアプリ本体層を分けてDockerイメージのレイヤーキャッシュを効かせる
- 起動時間短縮・省メモリが必要な場合は、Spring Native/GraalVMネイティブイメージ化(Spring Boot 3.x+GraalVM対応)を検討する

## 7. 用語・注意点まとめ
- Bean: Spring IoCコンテナが生成・管理するオブジェクトのこと
- ApplicationContext: BeanのライフサイクルとDIを管理するIoCコンテナの実体
- POJO(Plain Old Java Object): 特定のフレームワークの基底クラス継承等に依存しない、素のJavaオブジェクト
- Fat Jar(Executable Jar): 依存ライブラリと組み込みサーバを含む、単体で実行可能なjarファイル
- N+1問題: JPAでリレーション先を遅延取得する際、ループ内で件数分の追加クエリが発行されてしまう典型的なパフォーマンス問題。`fetch join`や`@EntityGraph`で対策する
- Spring Bootのバージョンとの対応表(Spring Boot 3.xはJava 17必須、Jakarta EE 9+(`javax.*`から`jakarta.*`へパッケージ変更)に対応)は移行時に特に注意する
