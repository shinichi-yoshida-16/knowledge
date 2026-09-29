# Vue.js Nuxt.jsについて
## app.vue
- <NuxtPage /> タグは必須、app.vueを置かない場合、Nuxtが内部でデフォルトのapp.vue(<NuxtPage />または<NuxtLayout><NuxtPage/></NuxtLayout>)を使用する
- <NuxtPage /> にルート先の.vueファイルのtemplate部分がマウントされる
