import axios from 'axios';
import Cookies from 'js-cookie';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add token to requests
api.interceptors.request.use((config) => {
  const token = Cookies.get('adminToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 || error.response?.status === 403) {
      Cookies.remove('adminToken');
      if (typeof window !== 'undefined') {
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

export interface ApiResponse<T = any> {
  return_code: string;
  message: string;
  data?: T;
  timestamp: string;
}

export const authApi = {
  login: async (email: string, password: string) => {
    const response = await api.post<ApiResponse & { user: any; token: string }>('/auth/admin-login', {
      email,
      password,
    });
    return response.data;
  },
};

export const menuApi = {
  // Menu items
  getMenuItems: async () => {
    const response = await api.get<ApiResponse<{ items: any[] }>>('/menu-admin/items');
    return response.data;
  },
  
  createMenuItem: async (name: string) => {
    const response = await api.post<ApiResponse<{ item: any }>>('/menu-admin/items', { name });
    return response.data;
  },
  
  updateMenuItem: async (id: number, name: string) => {
    const response = await api.put<ApiResponse<{ item: any }>>(`/menu-admin/items/${id}`, { name });
    return response.data;
  },
  
  deleteMenuItem: async (id: number) => {
    const response = await api.delete<ApiResponse>(`/menu-admin/items/${id}`);
    return response.data;
  },
  
  // Menu synonyms
  getSynonyms: async (menuItemId: number) => {
    const response = await api.get<ApiResponse<{ synonyms: any[] }>>(`/menu-admin/items/${menuItemId}/synonyms`);
    return response.data;
  },
  
  createSynonym: async (menuItemId: number, synonym: string) => {
    const response = await api.post<ApiResponse<{ synonym: any }>>(`/menu-admin/items/${menuItemId}/synonyms`, { synonym });
    return response.data;
  },
  
  updateSynonym: async (menuItemId: number, synonymId: number, synonym: string) => {
    const response = await api.put<ApiResponse<{ synonym: any }>>(`/menu-admin/items/${menuItemId}/synonyms/${synonymId}`, { synonym });
    return response.data;
  },
  
  deleteSynonym: async (menuItemId: number, synonymId: number) => {
    const response = await api.delete<ApiResponse>(`/menu-admin/items/${menuItemId}/synonyms/${synonymId}`);
    return response.data;
  },

  // New workflow endpoints
  searchSynonym: async (query: string) => {
    const response = await api.get<ApiResponse<{ mapping: any }>>(`/menu-admin/search-synonym?query=${encodeURIComponent(query)}`);
    return response.data;
  },

  mapSynonym: async (synonym: string, menuItemId?: number, createNewItem?: boolean, newItemName?: string) => {
    const response = await api.post<ApiResponse<{ synonym: any; action: string }>>('/menu-admin/map-synonym', {
      synonym,
      menu_item_id: menuItemId,
      create_new_item: createNewItem,
      new_item_name: newItemName,
    });
    return response.data;
  },
};

export default api;