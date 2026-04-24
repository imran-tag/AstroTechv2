import { Routes } from '@angular/router';
import { LoginComponent } from './auth/login/login.component';
import { RegisterComponent } from './auth/register/register.component';
import { MainLayoutComponent } from './layout/main-layout/main-layout.component';
import { AuthGuard } from './guards/auth.guard';

// Importez les DEUX composants distincts
import { ForgotPasswordComponent } from './auth/forgot-password/forgot-password.component';
import { ResetPasswordComponent } from './auth/reset-password/reset-password.component';

export const routes: Routes = [
    { path: '', redirectTo: 'login', pathMatch: 'full' },

    // Pages publiques
    { path: 'login', component: LoginComponent },
    { path: 'register', component: RegisterComponent },
    
    // Étape 1 : Demande de mail
    { path: 'forgot-password', component: ForgotPasswordComponent },
    
    // Étape 2 : Saisie du nouveau mot de passe (via le lien email)
    { path: 'reset-password/:token', component: ResetPasswordComponent },

    // Pages avec layout (protégées)
    {
        path: '',
        component: MainLayoutComponent,
        canActivate: [AuthGuard],
        children: [
            /** Dashboard & Profile **/
            { path: 'dashboard', loadComponent: () => import('./dashboard/dashboard.component').then(c => c.DashboardComponent) },
            { path: 'profile', loadComponent: () => import('./auth/profile/profile.component').then(c => c.ProfileComponent) },

            /** Affaires **/
            { path: 'affaires/edit', loadComponent: () => import('./affaires/edit/edit/edit.component').then(c => c.EditComponent) },
            { path: 'affaires/edit/:id', loadComponent: () => import('./affaires/edit/edit/edit.component').then(c => c.EditComponent) },
            { path: 'affaires/list', loadComponent: () => import('./affaires/list/list.component').then(c => c.ListComponent) },

            /** Clients **/
            { path: 'clients/list', loadComponent: () => import('./annuaire/list/list.component').then(c => c.ListComponent) },
            { path: 'clients/details/:id', loadComponent: () => import('./annuaire/details/details.component').then(c => c.DetailsComponent) },

            /** Techniciens **/
            { path: 'techniciens/list', loadComponent: () => import('./techniciens/list/list.component').then(c => c.ListComponent) },
            { path: 'techniciens/edit', loadComponent: () => import('./techniciens/edit/edit.component').then(c => c.EditComponent) },
            { path: 'techniciens/edit/:id', loadComponent: () => import('./techniciens/edit/edit.component').then(c => c.EditComponent) },
            { path: 'techniciens/equipe', loadComponent: () => import('./techniciens/equipe/equipe.component').then(c => c.EquipeComponent) },

            /** Referents **/
            { path: 'referents/list', loadComponent: () => import('./referents/list/list.component').then(c => c.ListComponent) },
            { path: 'referents/edit', loadComponent: () => import('./referents/edit/edit.component').then(c => c.EditComponent) },
            { path: 'referents/edit/:id', loadComponent: () => import('./referents/edit/edit.component').then(c => c.EditComponent) },

            /** Intervention **/
            { path: 'interventions', loadComponent: () => import('./intervention/choix-intervention/choix-intervention.component').then(c => c.ChoixInterventionComponent) },
            { path: 'interventions/list', loadComponent: () => import('./intervention/list/list.component').then(c => c.ListComponent) },
            { path: 'interventions/edit', loadComponent: () => import('./intervention/edit/edit/edit.component').then(c => c.EditComponent) },
            { path: 'interventions/edit/:id', loadComponent: () => import('./intervention/edit/edit/edit.component').then(c => c.EditComponent) },
            { path: 'interventions/details/:id', loadComponent: () => import('./intervention/details/details.component').then(c => c.DetailsComponent) },
            { path: 'interventions/planning', loadComponent: () => import('./intervention/planning/planning.component').then(c => c.PlanningComponent) },
        ]
    },

    { path: '**', redirectTo: 'login' }
];