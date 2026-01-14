import { createApp } from "vue";
import { createRouter, createWebHistory } from "vue-router";
import App from "./App.vue";
import PublicView from "./views/PublicView.vue";
import AdminView from "./views/AdminView.vue";
import AuthCallbackView from "./views/AuthCallbackView.vue";
import UserRegisterView from "./views/UserRegisterView.vue";
import ProfileView from "./views/ProfileView.vue";
import "./style.css";

const routes = [
  {
    path: "/",
    name: "public",
    component: PublicView,
  },
  {
    path: "/auth/callback",
    name: "auth-callback",
    component: AuthCallbackView,
  },
  {
    path: "/register",
    name: "register",
    component: UserRegisterView,
  },
  {
    path: "/admin",
    name: "admin",
    component: AdminView,
  },
  {
    path: "/profile",
    name: "profile",
    component: ProfileView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

const app = createApp(App);
app.use(router);
app.mount("#app");
