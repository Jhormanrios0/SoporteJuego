import { createApp } from "vue";
import { createRouter, createWebHistory } from "vue-router";
import App from "./App.vue";
import { initAuth, authInitializing } from "./services/authInit";
import PublicView from "./views/PublicView.vue";
import AdminView from "./views/AdminView.vue";
import AuthCallbackView from "./views/AuthCallbackView.vue";
import UserRegisterView from "./views/UserRegisterView.vue";
import ProfileView from "./views/ProfileView.vue";
import VipProfileView from "./views/VipProfileView.vue";
import PlayerProfileView from "./views/PlayerProfileView.vue";
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
  {
    path: "/player/:id",
    name: "player-profile",
    component: PlayerProfileView,
    props: true,
  },
  {
    path: "/vip/profile",
    name: "vip-profile",
    component: VipProfileView,
  },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

async function bootstrap() {
  // Inicializar sesión antes de montar para evitar flashes de UI
  try {
    await initAuth();
  } catch (e) {
    // noop
  }

  // Mostrar loader en transiciones de ruta para mejor UX
  router.beforeEach((to, from, next) => {
    try {
      authInitializing.value = true;
    } catch (e) {}
    next();
  });

  router.afterEach(() => {
    // pequeña espera visual para evitar parpadeos
    setTimeout(() => {
      try {
        authInitializing.value = false;
      } catch (e) {}
    }, 120);
  });

  const app = createApp(App);
  app.use(router);
  app.mount("#app");
}

bootstrap();
