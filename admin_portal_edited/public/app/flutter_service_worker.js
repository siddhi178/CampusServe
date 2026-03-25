'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "92d7b381181c04fc8c15792d9025e69f",
"assets/AssetManifest.bin.json": "ad9f286a2ff157c40b372ca64d66ecbf",
"assets/assets/auth.jpg": "98792c69b4eb4a855a8b599dfc90235d",
"assets/assets/beverages.png": "c2f998dd8a7f993a0cc45284a91024eb",
"assets/assets/bhimUPI.png": "40165e866f3e850e1d5d30dd2e412f04",
"assets/assets/breakfast.png": "f134a7dec624d6c2e44dc7635b035fb1",
"assets/assets/brownie.png": "5fe92b967b80dda8bf6b2eeb72bd85dc",
"assets/assets/buttermilk.png": "7df7161cea269473bb8c7d96142887d0",
"assets/assets/butter_naan.png": "d62ad109acad974ac9fce76e8df6c266",
"assets/assets/cheesecake.png": "5540b2b182a37a65e9e8d3e0d7667556",
"assets/assets/cheese_burger.png": "7d35d3c3eed94265ab3c02084047736e",
"assets/assets/chole_bhature.png": "bf40fc55acf18d81e8e6b9c3470d7bd9",
"assets/assets/coca_cola.png": "8f7ea6c80559add8980aa689dfc7b5c7",
"assets/assets/cold_coffee.png": "bb5982512533c8adf0c09967d70cac41",
"assets/assets/c_acc.jpg": "8ee3d710746d0c098bebc953d03cae72",
"assets/assets/dal_makhani.png": "4e0e41a1fdd42d2fc891b487964ae154",
"assets/assets/deserts.png": "9fd41a2a7a5361f07911faef1fbff673",
"assets/assets/falooda.png": "d80dbb99723685fdb074a988b0d66b05",
"assets/assets/fanta.png": "91b5648d9c6b8674938bfcaff92c130f",
"assets/assets/forgot_pass.jpg": "8bfc9f7c3a906dfd4fa4bd0df8ab9e55",
"assets/assets/frankie.png": "f6e52b9c0bcbe6014cb9b9edcb04ef53",
"assets/assets/fried_rice.png": "10bb981d662039dc33de3c95b24d4e98",
"assets/assets/Fries.png": "25ebcdae221eb54888f13a51d8d17757",
"assets/assets/garlic_naan.png": "c65bfcc3d83dab6bcd85eac72e6718ae",
"assets/assets/ginger_tea.png": "006f5ab1bfb3816ca5ee53ee893f6e33",
"assets/assets/gpay.png": "c08414832f664ab7b3106f6f553afc30",
"assets/assets/green_tea.png": "387e5b8cd425fda4a61c5d0be13d4a73",
"assets/assets/gulab_jamun.png": "d15d89acf80c5ce405a53cfd5b37292c",
"assets/assets/hot_coffee.png": "49864a3d6ab55be37a4f95ec020be9e5",
"assets/assets/ice-cream.png": "49d6c43bb3845987e78e6590eb242b58",
"assets/assets/iced_lemon_tea.png": "ea873a50fd6f1987379d09b214c22f28",
"assets/assets/idli_sambhar.png": "3a98295847938fe138ca5b37a03bfbb4",
"assets/assets/jalebi.png": "345dcd730f05e3d42d41d7905212df31",
"assets/assets/jeera_rice.png": "11718e2f65be5cae4243bde1c65adb4e",
"assets/assets/kheer.png": "fd8d1538c4717651ced4e1c248a34551",
"assets/assets/kulfi.png": "2d4f5d0d24cb75aed52f555bb3657416",
"assets/assets/lime_soda.png": "3d1ef407da87c978255239efbfe7011d",
"assets/assets/login.jpg": "e3f8dd1c5f9b8a54047f974c25f6d648",
"assets/assets/main_course.png": "532c1082aedd3b7f327843d7643da37a",
"assets/assets/mango_juice.png": "cf58cc31f2bcf83eaa49370d474c90aa",
"assets/assets/masala_dosa.png": "f52755a6dac329b1dcad1e0de8c0a8c1",
"assets/assets/masala_tea.png": "1430572b3ec5904afb2d5a4f945883b0",
"assets/assets/mineral_water.png": "0dda5c0865e6ad7164d6565e671746b3",
"assets/assets/nescafe_latte.png": "725b98546c6aa003b24b5ef6920ab520",
"assets/assets/noodles.png": "8b98570e95a0eaacad3c41bb3c56217b",
"assets/assets/on1.jpg": "9737a963952b779341ffe728a729542f",
"assets/assets/on2.jpg": "be0c88ec1de03f55d6477891634f82e3",
"assets/assets/on3.jpg": "c866436475db94d48e652fbbd77d1a83",
"assets/assets/orange_juice.png": "6346c2c853c05f65396cec123daf1b8f",
"assets/assets/palak_paneer.png": "bc8be1ef19561c3ef2539a575fe15a83",
"assets/assets/paneer_burger.png": "7bc1f56ead466dfd520429a4fbbe31b9",
"assets/assets/paneer_butter_masala.png": "42744a768e3f566f972c48b3a73fd67e",
"assets/assets/Paneer_Pizza.png": "5367e10c6446ed47d5b3d7b125191e71",
"assets/assets/paratha.png": "c615aa8651511bbed5641f94a8aa511b",
"assets/assets/pastry.png": "b298991c8dd206a80dfacee36a614aaf",
"assets/assets/Pav%2520Bhaji.jpg": "b835ad509131dd838288d6acfb16b202",
"assets/assets/paytm.png": "c0c535054b0782de5909ae8940e5b397",
"assets/assets/pay_on_counter.png": "e047ad42a15cd2b397595cc3ad85130f",
"assets/assets/phonepe.png": "762cb232667f9fc88fad166e99f22746",
"assets/assets/pohe.png": "c3ff309a15535c53628f4783aac5e4be",
"assets/assets/pulao.png": "ef0317ae0fb15522b69f3965cc62c56f",
"assets/assets/rabri.png": "4daf2b96317ea9e36e2883bae9681fb6",
"assets/assets/rasgulla.png": "9b0185b987a5db1b3920c18bd680b951",
"assets/assets/rasmalai.png": "455a6eac17f8a8c5bb986b84e4508a78",
"assets/assets/reset_pass.jpg": "ada357ea7e24f41210a80d9a279cfb47",
"assets/assets/reset_pass1.jpg": "806d8d7ea84bb4b0cf1b8978f5c8b531",
"assets/assets/roti.png": "5d793c7b6aee4683d4e6164222143694",
"assets/assets/samosa.png": "d75ac69a512ed3eaefe855d2faff2a31",
"assets/assets/sandwich.png": "f7ccd7652e9e59b8d53951a29046daf1",
"assets/assets/snacks.png": "9fa80bfab4f896f15e4962fd350ba7f3",
"assets/assets/splash.jpg": "132c3f98f1edafaa116843dedda70c28",
"assets/assets/sprite.png": "13a7059d838204e4c7fbc826cd93fbc3",
"assets/assets/upma.png": "16d2fc4433ba240db2cb23b898c2fd0a",
"assets/assets/vada.png": "f99cb7ebd9c494547cc4c8ac9c2461e9",
"assets/assets/vada_pav.png": "37290f8b3f3fb87427ebad92910b58ff",
"assets/assets/veg_biryani.png": "5a501bc7d403914ef8fb057e9c65fbe1",
"assets/assets/veg_burger.png": "9123c259c14004c62ed7f98a4a0c4ec4",
"assets/assets/welcome.jpg": "658c664b67e7ca81b457bf5aacf1cbe9",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "a7bef06ce1d8680a8d09eab198522711",
"assets/NOTICES": "10bfcde5181507a71e440fc9066fe442",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "290d91a72b1bac84b34bfc2da9d02f4d",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "acfffd1a083ede0eda1ab3d5f3f26ff8",
"/": "acfffd1a083ede0eda1ab3d5f3f26ff8",
"main.dart.js": "89be6eb2370d29e115480093cf51b2f2",
"manifest.json": "bf24c84c3bf99672a631c4f84464e793",
"version.json": "15235b5108d6a877ef74fe3317a96bf7"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
