'use client';

import { useState } from 'react';
import MenuItemForm from './MenuItemForm';

interface MenuItem {
  id: number;
  name: string;
  created_at: string;
}

interface MenuItemListProps {
  items: MenuItem[];
  selectedItem: MenuItem | null;
  onSelect: (item: MenuItem) => void;
  onUpdate: (id: number, name: string) => void;
  onDelete: (id: number) => void;
}

export default function MenuItemList({
  items,
  selectedItem,
  onSelect,
  onUpdate,
  onDelete,
}: MenuItemListProps) {
  const [editingId, setEditingId] = useState<number | null>(null);

  const handleEdit = (item: MenuItem) => {
    setEditingId(item.id);
  };

  const handleUpdate = (id: number, name: string) => {
    onUpdate(id, name);
    setEditingId(null);
  };

  const handleCancelEdit = () => {
    setEditingId(null);
  };

  if (items.length === 0) {
    return <p className="text-gray-500">No menu items yet. Add one above!</p>;
  }

  return (
    <div className="space-y-2">
      {items.map((item) => (
        <div
          key={item.id}
          className={`p-3 rounded-md border ${
            selectedItem?.id === item.id
              ? 'border-indigo-500 bg-indigo-50'
              : 'border-gray-200 hover:border-gray-300'
          }`}
        >
          {editingId === item.id ? (
            <div className="space-y-2">
              <MenuItemForm
                initialValue={item.name}
                submitLabel="Save"
                onSubmit={(name) => handleUpdate(item.id, name)}
              />
              <button
                onClick={handleCancelEdit}
                className="text-sm text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
            </div>
          ) : (
            <div className="flex items-center justify-between">
              <button
                onClick={() => onSelect(item)}
                className="flex-1 text-left"
              >
                <span className="font-medium">{item.name}</span>
              </button>
              <div className="flex gap-2">
                <button
                  onClick={() => handleEdit(item)}
                  className="text-sm text-indigo-600 hover:text-indigo-800"
                >
                  Edit
                </button>
                <button
                  onClick={() => onDelete(item.id)}
                  className="text-sm text-red-600 hover:text-red-800"
                >
                  Delete
                </button>
              </div>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}