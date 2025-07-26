'use client';

import { useState, useEffect } from 'react';
import { menuApi } from '@/lib/api';
import LogoutButton from '@/components/LogoutButton';

interface MenuItem {
  id: number;
  name: string;
  created_at: string;
}

export default function HomePage() {
  const [properMenuName, setProperMenuName] = useState('');
  const [allMenuItems, setAllMenuItems] = useState<MenuItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<number | null>(null);

  useEffect(() => {
    loadAllMenuItems();
  }, []);

  const loadAllMenuItems = async () => {
    try {
      const response = await menuApi.getMenuItems();
      if (response.return_code === 'SUCCESS') {
        setAllMenuItems(response.data?.items || []);
      }
    } catch (err) {
      console.error('Failed to load menu items');
    }
  };

  const handleSetupMenuItem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!properMenuName.trim()) return;

    // Validate: only full words allowed (no spaces or phrases)
    if (properMenuName.trim().includes(' ')) {
      setError('Only full words are allowed. No spaces or phrases.');
      setProperMenuName(''); // Clear the input
      return;
    }
    
    try {
      setLoading(true);
      setError('');
      setSuccess('');
      
      const upperName = properMenuName.trim().toUpperCase();

      // First check if menu item already exists
      const itemsResponse = await menuApi.getMenuItems();
      if (itemsResponse.return_code === 'SUCCESS') {
        let item = itemsResponse.data?.items.find(i => i.name === upperName);
        
        if (!item) {
          // Create new menu item
          const response = await menuApi.createMenuItem(upperName);
          if (response.return_code === 'SUCCESS') {
            // Refresh items list to get the new item
            const newItemsResponse = await menuApi.getMenuItems();
            if (newItemsResponse.return_code === 'SUCCESS') {
              item = newItemsResponse.data?.items.find(i => i.name === upperName);
            }
          }
        }
        
        if (item) {
          // Add the main item name as a synonym too (for exact matches)
          await menuApi.mapSynonym(upperName, item.id);
          
          // Show success and reset for next item
          setProperMenuName('');
          await loadAllMenuItems(); // Refresh the list
          setSuccess(`Added "${upperName}"`);
          
          setTimeout(() => {
            setSuccess('');
            document.getElementById('menu-name-input')?.focus();
          }, 1000);
        }
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to setup menu item');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteItem = async (itemId: number) => {
    try {
      setLoading(true);
      setError('');
      setSuccess('');

      const response = await menuApi.deleteMenuItem(itemId);

      if (response.return_code === 'SUCCESS') {
        await loadAllMenuItems(); // Refresh the list
        setSuccess('Item deleted');
        setTimeout(() => setSuccess(''), 2000);
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to delete item');
    } finally {
      setLoading(false);
      setShowDeleteConfirm(null);
    }
  };

  // Auto-uppercase input with space prevention
  const handleMenuNameChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    // Prevent spaces from being entered
    if (!value.includes(' ')) {
      setProperMenuName(value.toUpperCase());
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900">Splitdine Menu Management</h1>
          <LogoutButton />
        </div>

        {/* Main content grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Entry form */}
          <div className="lg:col-span-2">
            <div className="bg-white shadow rounded-lg p-6">
              <form onSubmit={handleSetupMenuItem} className="space-y-4">
                <div>
                  <input
                    id="menu-name-input"
                    type="text"
                    value={properMenuName}
                    onChange={handleMenuNameChange}
                    placeholder='e.g., "CAESAR", "CHICKEN", "GARLIC" (no spaces allowed)'
                    className="block w-full px-4 py-4 text-xl font-mono border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                    autoFocus
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading || !properMenuName.trim()}
                  className="w-full px-4 py-3 text-lg bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
                >
                  {loading ? 'Adding...' : 'Add Menu Item'}
                </button>
              </form>

              {/* Messages */}
              {error && (
                <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-md">
                  <p className="text-red-800">{error}</p>
                </div>
              )}

              {success && (
                <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-md">
                  <p className="text-green-800">{success}</p>
                </div>
              )}
            </div>
          </div>

          {/* Sidebar - Latest items */}
          <div className="bg-white shadow rounded-lg p-4">
            <div className="text-center mb-4">
              <p className="text-green-800 font-semibold">Total: {allMenuItems.length}</p>
            </div>

            {allMenuItems.length > 0 && (
              <div className="space-y-2">
                {allMenuItems
                  .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
                  .slice(0, 5)
                  .map((item) => (
                    <div key={item.id} className="flex justify-between items-center p-2 bg-gray-50 rounded text-sm">
                      <span className="font-mono text-gray-800 truncate flex-1 mr-2">{item.name}</span>
                      {showDeleteConfirm === item.id ? (
                        <div className="flex gap-1 flex-shrink-0">
                          <button
                            onClick={() => handleDeleteItem(item.id)}
                            disabled={loading}
                            className="text-xs px-1 py-1 bg-red-600 text-white rounded hover:bg-red-700 disabled:opacity-50"
                          >
                            ✓
                          </button>
                          <button
                            onClick={() => setShowDeleteConfirm(null)}
                            disabled={loading}
                            className="text-xs px-1 py-1 bg-gray-300 text-gray-700 rounded hover:bg-gray-400 disabled:opacity-50"
                          >
                            ✕
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => setShowDeleteConfirm(item.id)}
                          disabled={loading}
                          className="text-red-600 hover:text-red-800 text-xs px-2 py-1 hover:bg-red-50 rounded disabled:opacity-50 flex-shrink-0"
                        >
                          ×
                        </button>
                      )}
                    </div>
                  ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}