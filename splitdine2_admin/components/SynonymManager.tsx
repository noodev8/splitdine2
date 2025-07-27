'use client';

import { useState, useEffect } from 'react';
import { menuApi } from '@/lib/api';

interface MenuItem {
  id: number;
  name: string;
}

interface Synonym {
  id: number;
  synonym: string;
  created_at: string;
}

interface SynonymManagerProps {
  menuItem: MenuItem;
}

export default function SynonymManager({ menuItem }: SynonymManagerProps) {
  const [synonyms, setSynonyms] = useState<Synonym[]>([]);
  const [newSynonym, setNewSynonym] = useState('');
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editValue, setEditValue] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSynonyms();
  }, [menuItem.id]);

  const loadSynonyms = async () => {
    try {
      setLoading(true);
      const response = await menuApi.getSynonyms(menuItem.id);
      if (response.return_code === 'SUCCESS') {
        // Filter out synonyms that match the main menu item name
        const filteredSynonyms = (response.data?.synonyms || []).filter(
          (synonym: Synonym) => synonym.synonym.toUpperCase() !== menuItem.name.toUpperCase()
        );
        setSynonyms(filteredSynonyms);
      }
    } catch (err) {
      console.error('Failed to load synonyms:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSynonym.trim()) return;

    // Validate: only full words allowed (no spaces or phrases)
    if (newSynonym.trim().includes(' ')) {
      alert('Only full words are allowed. No spaces or phrases.');
      setNewSynonym(''); // Clear the input field
      return;
    }

    // Prevent adding the main menu item name as a synonym
    if (newSynonym.trim().toUpperCase() === menuItem.name.toUpperCase()) {
      alert('Cannot add the main menu item name as a synonym.');
      setNewSynonym(''); // Clear the input field
      return;
    }

    try {
      const response = await menuApi.createSynonym(menuItem.id, newSynonym.trim());
      if (response.return_code === 'SUCCESS') {
        await loadSynonyms();
        setNewSynonym('');
        // Auto-focus back to input after successful add
        setTimeout(() => {
          const input = document.querySelector('input[placeholder="Add synonym"]') as HTMLInputElement;
          input?.focus();
        }, 100);
      } else {
        alert(response.message);
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to add synonym');
    }
  };

  const handleUpdate = async (synonymId: number) => {
    if (!editValue.trim()) return;

    // Validate: only full words allowed (no spaces or phrases)
    if (editValue.trim().includes(' ')) {
      alert('Only full words are allowed. No spaces or phrases.');
      cancelEdit(); // Cancel the edit and clear the form
      return;
    }

    // Prevent updating to the main menu item name
    if (editValue.trim().toUpperCase() === menuItem.name.toUpperCase()) {
      alert('Cannot use the main menu item name as a synonym.');
      cancelEdit(); // Cancel the edit and clear the form
      return;
    }

    try {
      const response = await menuApi.updateSynonym(menuItem.id, synonymId, editValue.trim());
      if (response.return_code === 'SUCCESS') {
        await loadSynonyms();
        setEditingId(null);
        setEditValue('');
      } else {
        alert(response.message);
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to update synonym');
    }
  };

  const handleDelete = async (synonymId: number) => {
    if (!confirm('Are you sure you want to delete this synonym?')) return;

    try {
      const response = await menuApi.deleteSynonym(menuItem.id, synonymId);
      if (response.return_code === 'SUCCESS') {
        await loadSynonyms();
      } else {
        alert(response.message);
      }
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to delete synonym');
    }
  };

  const startEdit = (synonym: Synonym) => {
    setEditingId(synonym.id);
    setEditValue(synonym.synonym);
  };

  const cancelEdit = () => {
    setEditingId(null);
    setEditValue('');
  };

  if (loading) {
    return <p className="text-gray-500">Loading synonyms...</p>;
  }

  return (
    <div className="space-y-4">
      <form onSubmit={handleAdd} className="flex gap-2">
        <input
          type="text"
          value={newSynonym}
          onChange={(e) => {
            const value = e.target.value;
            // Prevent spaces from being entered
            if (!value.includes(' ')) {
              setNewSynonym(value);
            }
          }}
          placeholder="Add synonym"
          className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500 uppercase"
          style={{ textTransform: 'uppercase' }}
          spellCheck={false}
          autoFocus
        />
        <button
          type="submit"
          className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
        >
          Add
        </button>
      </form>

      <div className="space-y-2">
        {synonyms.length === 0 ? (
          <p className="text-gray-500">No synonyms yet. Add one above!</p>
        ) : (
          synonyms.map((synonym) => (
            <div
              key={synonym.id}
              className="flex items-center justify-between p-3 bg-gray-50 rounded-md"
            >
              {editingId === synonym.id ? (
                <div className="flex-1 flex gap-2">
                  <input
                    type="text"
                    value={editValue}
                    onChange={(e) => {
                      const value = e.target.value;
                      // Prevent spaces from being entered
                      if (!value.includes(' ')) {
                        setEditValue(value);
                      }
                    }}
                    className="flex-1 px-2 py-1 border border-gray-300 rounded uppercase"
                    style={{ textTransform: 'uppercase' }}
                    spellCheck={false}
                    autoFocus
                  />
                  <button
                    onClick={() => handleUpdate(synonym.id)}
                    className="text-sm text-green-600 hover:text-green-800"
                  >
                    Save
                  </button>
                  <button
                    onClick={cancelEdit}
                    className="text-sm text-gray-600 hover:text-gray-800"
                  >
                    Cancel
                  </button>
                </div>
              ) : (
                <>
                  <span className="uppercase">{synonym.synonym}</span>
                  <div className="flex gap-2">
                    <button
                      onClick={() => startEdit(synonym)}
                      className="text-sm text-indigo-600 hover:text-indigo-800"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDelete(synonym.id)}
                      className="text-sm text-red-600 hover:text-red-800"
                    >
                      Delete
                    </button>
                  </div>
                </>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}