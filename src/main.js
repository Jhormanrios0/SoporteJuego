import { createApp } from "vue";
import { createRouter, createWebHistory } from "vue-router";
import App from "./App.vue";
import PublicView from "./views/PublicView.vue";
import AdminView from "./views/AdminView.vue";
import "./style.css";

const routes = [
  {
    path: "/",
    name: "public",
    component: PublicView,
  },
  {
    path: "/admin",
    name: "admin",
    component: AdminView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

const app = createApp(App);
app.use(router);
app.mount("#app");
