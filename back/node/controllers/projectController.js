const Project = require('../models/projectModel')
const User = require('../models/usersModel')
const Invoice = require('../models/invoicesModel');
const Pays = require('../models/paysModel');
const mongoose = require('mongoose');
const axios= require ('axios');
const { Types: { ObjectId } } = mongoose;

exports.getAllProjectsWithManager = async (req, res) => {
  try {
      const userId = req.user.userId; 
      console.log("useid ta3 RF");
      console.log(userId);
    // Trouver les IDs des managers créés par cet utilisateur
    const managersCreatedByUser = await User.find({ creepar: userId }).select('_id');
    const managerIds = managersCreatedByUser.map(manager => manager._id);
    
    console.log("Managers créés par l'utilisateur:", managerIds);
    
    const query = {
      $or: [
        { manager: userId },
        { manager: { $in: managerIds } }
      ]
    };
     
    const projects = await Project.find(query)
      .populate('manager', 'name')
      .exec();

      res.status(200).json(projects);
  } catch (error) {
      console.error('Error in getAllProjectsWithManager:', error);
      res.status(500).json({ 
          message: "Erreur lors de la récupération des projets", 
          error: error.message 
      });
  }
};
exports.getAllProjectsWithManagerPagination = async (req, res) => {
  const { page, limit, search } = req.query;
  console.log("pagination de projet avec recherche", { page, limit, search });
  const skip = (page - 1) * limit;
  
  try {
    const userId = req.user.userId; 
    
    // Trouver les IDs et noms des managers créés par cet utilisateur
    const managersCreatedByUser = await User.find({ creepar: userId }).select('_id name');
    const managerIds = managersCreatedByUser.map(manager => manager._id);
    
    console.log("Managers créés par l'utilisateur:", managersCreatedByUser.map(m => ({id: m._id, name: m.name})));
    
    const baseQuery = {
      $or: [
        { manager: userId },
        { manager: { $in: managerIds } }
      ]
    };
    
    // Si un terme de recherche est fourni
    let finalQuery = baseQuery;
    if (search) {
      // Trouver les managers dont le nom correspond à la recherche
      const matchingManagers = await User.find({
        name: { $regex: search, $options: 'i' },
        _id: { $in: [userId, ...managerIds] }
      }).select('_id');
      
      const matchingManagerIds = matchingManagers.map(m => m._id);
      
      finalQuery = {
        $and: [
          baseQuery,
          {
            $or: [
              { name: { $regex: search, $options: 'i' } }, // Recherche sur le nom du projet
              { manager: { $in: matchingManagerIds } } // Recherche sur le nom du manager
            ]
          }
        ]
      };
    }
    
    console.log("Requête finale:", JSON.stringify(finalQuery, null, 2));
    
    const totalCount = await Project.countDocuments(finalQuery);
    console.log("Nombre total de projets trouvés:", totalCount);
    
    // Récupérer les projets paginés avec le populate pour le manager
    const projects = await Project.find(finalQuery)
      .skip(skip)
      .limit(limit)
      .populate('manager', 'name') // Important pour avoir le nom du manager
      .sort({ updatedAt: -1 })
      .exec();
    
    const totalPages = Math.ceil(totalCount / limit);
    console.log("Total pages:", totalPages, "Total count:", totalCount);

    res.status(200).json({
      projects: projects,
      pagination: {
        totalItems: totalCount,
        totalPages: totalPages,
        currentPage: parseInt(page),
        itemsPerPage: parseInt(limit),
        hasNextPage: parseInt(page) < totalPages,
        hasPreviousPage: parseInt(page) > 1
      }
    });
  } catch (error) {
    console.error("Erreur détaillée:", error);
    res.status(500).json({ 
      message: "Erreur lors de la récupération des projets",
      error: error.message 
    });
  }
};

exports.getProjectsByManagerId = async (req, res) => {
  try {
      const managerId = req.params.id;
      console.log(req.params);
      console.log('manageris',managerId);

      const projects = await Project.find({ manager: managerId })
          .populate('manager', 'name') // Récupère seulement le nom du manager
          .exec();

      res.status(200).json(projects);
  } catch (error) {
      console.error("Erreur détaillée:", error);
      res.status(500).json({ 
          message: "Erreur lors de la récupération des projets",
          error: error.message 
      });
  }

};
  
exports.getProjectsByManagerIdPagination = async (req, res) => {
  const { page, limit , search} = req.query;
  console.log("pagination de projet");
  console.log(page, limit, search);
  //console.log("Query params:", req.query);
  const skip = (page - 1) * limit;
  
  try {
    const managerId = req.params.id;
    console.log(req.params);
    console.log('manageris', managerId);
  let searchFilter = { manager: managerId };
      
  // Ajouter le filtre de recherche par nom si présent
  if (search && search.trim() !== '') {
    searchFilter.name  = { $regex: search, $options: 'i' }; // Recherche insensible à la casse
  }

  // Compter le nombre total de projets correspondant aux critères
  const totalCount = await Project.countDocuments(searchFilter);

  // Récupérer les projets paginés avec les filtres
  const projects = await Project.find(searchFilter)
    .skip(skip)
    .limit(parseInt(limit))
    .populate('manager', 'name')
    .exec();

    const totalPages = Math.ceil(totalCount / limit);
    console.log("page",totalPages,"count",totalCount);
    res.status(200).json({
      projects: projects,
      pagination: {
        totalItems: totalCount,
        totalPages: totalPages,
        currentPage: parseInt(page),
        itemsPerPage: parseInt(limit),
        hasNextPage: parseInt(page) < totalPages,
        hasPreviousPage: parseInt(page) > 1
      }
    });
    //console.log(res);
  } catch (error) {
    console.error("Erreur détaillée:", error);
    res.status(500).json({ 
      message: "Erreur lors de la récupération des projets",
      error: error.message 
    });
  }
};
  
exports.setCurrentProject = async (req, res) => {
    try {
      const { projectId } = req.body;
      console.log("projectId ",projectId);
      console.log('req',req.body);
      console.log("req.user.id setCurrentProject ",req.user.userId );
      mongoose.set('debug', true);
    const { modifiedCount } = await User.updateOne(
      { _id: req.user.userId },
      { $set: { currentProject: projectId } }
    );
    console.log("Documents modifiés:", modifiedCount); // Doit être 1
  
      res.status(200).json({ 
        success: true,
        message: 'Projet courant mis à jour'
      });
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  };
  
  
  exports.getCurrentProject = async (req, res) => {
    try {
      const user = await User.findById(req.user.userId)
        .populate('currentProject', 'name status');
      
      res.status(200).json(user.currentProject);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  };
exports.getcurrentdevisepays = async (req, res) => {
  try {
    const { name } = req.query;
    console.log('Recherche de devise pour le pays:', name);
    
    if (!name) {
      return res.status(400).json({ error: 'Country name is required' });
    }

    try {
      const country = await Pays.findOne({ name });
      
      if (country && country.currency) {
        console.log('Devise trouvée en base de données:', country.currency);
        return res.json({
          currency: country.currency
        });
      }
    } catch (dbError) {
      console.error('Erreur lors de la recherche en base de données:', dbError);
    }
    
  
    try {
      console.log('Recherche via API REST Countries pour:', name);
      const response = await axios.get(`https://restcountries.com/v3.1/name/${encodeURIComponent(name)}`, {
        timeout: 5000 // 5 secondes
      });
      
      if (response.data && response.data.length > 0) {
        // Trouver le pays qui correspond le mieux au nom recherché
        const matchingCountry = response.data.find(country => {
          const countryNames = [
            country.name.common.toLowerCase(),
            country.name.official.toLowerCase()
          ];
          
          // Ajouter les traductions françaises si disponibles
          if (country.translations?.fra) {
            countryNames.push(country.translations.fra.common.toLowerCase());
            countryNames.push(country.translations.fra.official.toLowerCase());
          }
          
          // Ajouter les noms natifs si disponibles
          if (country.name.nativeName?.fra) {
            countryNames.push(country.name.nativeName.fra.common.toLowerCase());
            countryNames.push(country.name.nativeName.fra.official.toLowerCase());
          }
          
          return countryNames.includes(name.toLowerCase());
        }) || response.data[0]; // Prendre le premier pays si pas de correspondance exacte
        
        if (matchingCountry.currencies) {
          // Prendre le premier code de devise disponible
          const currencyCode = Object.keys(matchingCountry.currencies)[0];
          console.log('Devise trouvée via API:', currencyCode);
          
          return res.json({
            currency: currencyCode
          });
        }
      }
      
      return res.status(404).json({ error: 'Currency information not found for this country' });
      
    } catch (apiError) {
      console.error('Erreur lors de la recherche via API:', apiError.message);
      return res.status(500).json({ 
        error: 'Error fetching from external API',
        details: apiError.message
      });
    }
    
  } catch (error) {
    console.error('Error fetching country currency:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};


exports.fetchcountries = async (req, res) => {
  try {
    const { query } = req.query;
    console.log(query);
    
    if (!query || query.length < 2) {
      return res.status(400).json({ 
        error: 'Un paramètre de requête valide (min 2 caractères) est requis' 
      });
    }
    
    
    try {
      //  ^ mta3 début 
      const regexPattern = new RegExp(`^${query}`, 'i');
      const dbCountries = await Pays.find(
        { name: { $regex: regexPattern } },
        'name'
      ).limit(10);

      if (dbCountries && dbCountries.length > 0) {
        console.log(`${dbCountries.length} pays trouvés en base de données`);
        const resultList = dbCountries.map(country => ({
          nom: country.name
        }));
        console.log(resultList);
        return res.status(200).json(resultList);
      }
    } catch (dbError) {
      console.error('Erreur avec la base de données:', dbError);
      
    }

    // REST Countries
    try {
      console.log('api');
      const response = await axios.get(`https://restcountries.com/v3.1/name/${encodeURIComponent(query)}`, {
        timeout: 5000 //5 secounda
      });
      
      if (response.data && response.data.length > 0) {
        // Filtrage
        const apiResults = response.data
          .map(country => {
            try {
              const frenchName = country.name.nativeName?.fra?.common || 
                                country.translations?.fra?.common || 
                                country.name.common;
              //const currency =  country.codeDevise;
              let currencyCode = null;
              if (country.currencies) {
                // Prendre le premier code de devise disponible
                currencyCode = Object.keys(country.currencies)[0];
              }
              return {
                nom: frenchName,
                originalName: country.name.common, // filtrage
                currencyCode: currencyCode
              };
            } catch (e) {
              console.error('Error processing country data:', e);
              return null;
            }
          })
          .filter(Boolean) // Éliminer les résultats null
          .filter(country => {
            // Vérifier si le nom commence par la requête (insensible à la casse)
            return country.nom.toLowerCase().startsWith(query.toLowerCase()) ||
                   country.originalName.toLowerCase().startsWith(query.toLowerCase());
          })
          .map(country => ({ nom: country.nom ,currencies:country.currencyCode})); // Garder uniquement le nom dans le résultat final
        
        if (apiResults.length > 0) {
          console.log("fetchcountries");
          console.log(apiResults);
          return res.status(200).json(apiResults);
        }
      }
    } catch (apiError) {
      if (apiError.response?.status === 404) {
        console.log('Aucun pays trouvé via API');
      } else {
        console.error('Error fetching from API:', apiError.message);
      }
    }
    
    // Si aucun résultat nulle part
    return res.status(404).json({ message: 'Aucun pays trouvé' });
    
  } catch (error) {
    console.error('Erreur lors de la recherche:', error);
    return res.status(500).json({
      error: 'Erreur serveur',
      details: error.message
    });
  }
};

//
exports.update =  async (req, res) => {
  const projectId = req.params.id;
  const { status } = req.body;
  // Ici, tu mets à jour le projet dans ta base de données
  // Exemple avec Mongoose :
  console.log("update terminer");
  console.log(projectId,status);
  try {
    await Project.findByIdAndUpdate(projectId, { status });
    res.status(200).json({ message: 'Statut mis à jour' });
  } catch (err) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
};

///dashboardsattes
exports.getDashboardStats = async (req, res) => {
  try {
    // Get project count
    const projectCount = await Project.countDocuments();
    
    // Count unique countries in projects
    const countries = await Project.distinct('pays');
    const countryCount = countries.length;
    
    // Count unique suppliers in invoices
    const suppliers = await Invoice.distinct('company');
    const supplierCount = suppliers.length;
    
    // Get invoice count
    const invoiceCount = await Invoice.countDocuments();

    // Return the dashboard stats
    res.status(200).json({
      projectCount,
      countryCount,
      supplierCount,
      invoiceCount
    });
    //console.log(res);
  } catch (error) {
    console.error('Error retrieving dashboard stats:', error);
    res.status(500).json({ 
      message: 'Error retrieving dashboard statistics',
      error: error.message 
    });
  }
};

//
exports.getMonthlyInvoiceStats = async (req, res) => {
  try {
    const currentDate = new Date();
    const months = [];
    
    // Générer les 7 derniers mois
    for (let i = 11; i >= 0; i--) {
      const date = new Date(currentDate);
      date.setMonth(date.getMonth() - i);
      
      const monthName = date.toLocaleString('default', { month: 'short' });
      const year = date.getFullYear();
      const month = date.getMonth() + 1;
      
      // Compter les factures pour ce mois
      const count = await Invoice.countDocuments({
        date: {
          $gte: new Date(year, month - 1, 1),
          $lt: new Date(year, month, 1)
        }
      });
      
      months.push({
        month: monthName,
        count: count *100 // hethi rani dhrabtha fi 100
      });
    }
    
    res.json(months);
    //console.log(months);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
/*
// hethi ta3 vente w produit par jours 
exports.dailyStats=async (req, res) => {
  try {
    // 1. Récupérer les 7 derniers jours
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      days.push(date);
    }

    // 2. Formater les labels (Lun, Mar, etc.)
    const labels = days.map(d => 
      d.toLocaleDateString('fr-FR', { weekday: 'short' })
    );

    // 3. Compter les produits par jour
    const products = await Promise.all(days.map(async day => {
      const start = new Date(day);
      start.setHours(0, 0, 0, 0);
      
      const end = new Date(day);
      end.setHours(23, 59, 59, 999);
      
      const invoices = await Invoice.find({ 
        date: { $gte: start, $lte: end }
      }).populate('items');
      //
      const productNames = [];

      for (const invoice of invoices) {
        for (const item of invoice.items) {
          productNames.push(item.description); // ou item.nom selon ton modèle
        }
      }
      //
      console.log("noooms")
      console.log(productNames);
      return invoices.reduce((sum, invoice) => 
        sum + invoice.items.length, 0
      );
    }));

   // 4. Calculer les achats en euros par jour
const purchases = await Promise.all(days.map(async day => {
  const start = new Date(day);
  start.setHours(0, 0, 0, 0);
  
  const end = new Date(day);
  end.setHours(23, 59, 59, 999);
  
 const invoices = await Invoice.find({ 
    date: { $gte: start, $lte: end }
  }).populate({
    path: 'currency', // Le champ 'currency' 
    model: 'Pays', // Le modèle 'Pays' 
    select: 'tauxdechangeeuro currency'// 'tauxdechangeeuro'
  });
  console.log("invooooooooooices");
  console.log(invoices);
  
  return invoices.reduce(async (sumPromise, invoice) => {
    const sum = await sumPromise;
    const exchangeRate = invoice.currency ? invoice.currency.tauxdechangeeuro : null;
    
    // Si le taux n'est pas disponible dans la base, on peut:
    // Option 1: Utiliser une API externe
    // Option 2: Utiliser une valeur par défaut
    if (!exchangeRate) {
      //exchangeRate = await fetchExchangeRateFromAPI(invoice.currency.code);
      // OU
      exchangeRate = getDefaultExchangeRate(invoice.currency);
    }
    console.log(`Facture total: ${invoice.total}, taux: ${exchangeRate}`);

    return sum + (invoice.total * exchangeRate);
  }, Promise.resolve(0));
}));
    res.json({
      labels,
      products,
      purchases: purchases.map(p => parseFloat(p.toFixed(2)))
    });
    console.log({labels,
      products,
      purchases: purchases.map(p => parseFloat(p.toFixed(2)))});
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};*/
exports.dailyStats = async (req, res) => {
  try {
    // 1. Récupérer les 7 derniers jours
    const days = Array.from({ length: 7 }, (_, i) => {
      const date = new Date();
      date.setDate(date.getDate() - (6 - i));
      return date;
    });

    // 2. Formater les labels
    const labels = days.map(d => 
      d.toLocaleDateString('fr-FR', { weekday: 'short' })
    );

    // 3. Compter les produits par jour
    const products = await Promise.all(days.map(async day => {
      const start = new Date(day);
      start.setHours(0, 0, 0, 0);
      const end = new Date(day);
      end.setHours(23, 59, 59, 999);
      
      const invoices = await Invoice.find({ 
        date: { $gte: start, $lte: end }
      }).populate('items');
      
      return invoices.reduce((sum, invoice) => sum + invoice.items.length, 0);
    }));

    // 4. Récupérer tous les taux de change disponibles
    const allCurrencies = await Pays.find({}, 'currency tauxdechangeeuro');
    const currencyMap = new Map(allCurrencies.map(c => [c.currency, c.tauxdechangeeuro]));

    // 5. Calculer les achats en euros par jour
    const purchases = await Promise.all(days.map(async day => {
      const start = new Date(day);
      start.setHours(0, 0, 0, 0);
      const end = new Date(day);
      end.setHours(23, 59, 59, 999);
      
      const invoices = await Invoice.find({ 
        date: { $gte: start, $lte: end }
      });

      let total = 0;
      for (const invoice of invoices) {
        let exchangeRate;
        
        // Essayer d'abord l'API
        try {
          if (invoice.currency) {
            exchangeRate = await fetchExchangeRateFromAPI(invoice.currency);
          } else {
            exchangeRate = currencyMap.get(invoice.currency) || 1;
          }
        } catch (apiError) {
          console.error('API failed, using DB rate:', apiError);
          exchangeRate = currencyMap.get(invoice.currency) || 1;
        }
        
        total += invoice.total * exchangeRate;
      }
      return total;
    }));
      console.log({
        labels,
        products,
        purchases: purchases.map(p => parseFloat(p.toFixed(2)))
      })
    res.json({
      labels,
      products,
      purchases: purchases.map(p => parseFloat(p.toFixed(2)))
    });
    
  } catch (error) {
    console.error('Error in dailyStats:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
async function fetchExchangeRateFromAPI(currencyCode) {
  console.log("api mta3 la3bed")
  try {
    const response = await axios.get(`https://api.exchangerate-api.com/v4/latest/EUR`);
    return response.data.rates[currencyCode] || 1; 
  } catch (error) {
    console.error('Erreur API taux de change:', error);
    return getDefaultExchangeRate(currencyCode);
  }
}
async function getDefaultExchangeRate(currencyCode) {
  console.log("api mte3i")
  const currency = await Pays.findOne({ currency: currencyCode });
  return currency?.tauxdechangeeuro || 1; // 1 si non trouvé (EUR)
}


//
//chart 
/*
exports.fetchtop5item = async (req, res) => {
  try {
    const result = await Invoice.aggregate([
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.description",
          totalQuantity: { $sum: { $toInt: "$items.quantity" } },
          avgUnitPrice: { $avg: "$items.unit_price" }
        }
      },
      { $sort: { totalQuantity: -1 } },
      { $limit: 5 },
      {
        $project: {
          description: "$_id",
          totalQuantity: 1,
          avgUnitPrice: { $round: ["$avgUnitPrice", 2] },
          _id: 0
        }
      }
    ]);
    console.log('topitems');
    console.log(result);
    res.json({ topItems: result });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};*/
//
exports.fetchtop5item = async (req, res) => {
  console.log('hiii')
  try {
    const result = await Invoice.aggregate([
      { $unwind: "$items" },
      // Filtrer les éléments avec quantity vide ou nulle
      {
        $match: {
          "items.quantity": { 
            $exists: true, 
            $ne: null, 
            $ne: "" 
          }
        }
      },
      {
        $group: {
          _id: "$items.description",
          totalQuantity: { 
            $sum: { 
              $convert: {
                input: "$items.quantity",
                to: "int",
                onError: 0,
                onNull: 0
              }
            }
          },
        }
      },
      { $sort: { totalQuantity: -1 } },
      {
        $facet: {
          top4: [
            { $limit: 4 },
            {
              $project: {
                label: "$_id",
                value: "$totalQuantity",
                _id: 0
              }
            }
          ],
          others: [
            { $skip: 4 },
            {
              $group: {
                _id: null,
                value: { $sum: "$totalQuantity" }
              }
            },
            {
              $project: {
                label: "Autres",
                value: 1,
                _id: 0
              }
            }
          ]
        }
      },
      {
        $project: {
          combined: { $concatArrays: ["$top4", "$others"] }
        }
      },
      { $unwind: "$combined" },
      { $replaceRoot: { newRoot: "$combined" } }
    ]);

    console.log(result);
    res.json({ chartData: result });
  } catch (error) {
    console.error('Erreur dans fetchtop5item:', error);
    res.status(500).json({ error: error.message });
  }
};
/*
exports.fetchtop5item = async (req, res) => {
  console.log('hiii')
  try {
    const result = await Invoice.aggregate([
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.description",
          totalQuantity: { $sum: { $toInt: "$items.quantity" } },
        }
      },
      { $sort: { totalQuantity: -1 } },
      {
        $facet: {
          top4: [
            { $limit: 4 },
            {
              $project: {
                label: "$_id",
                value: "$totalQuantity",
                _id: 0
              }
            }
          ],
          others: [
            { $skip: 4 },
            {
              $group: {
                _id: null,
                value: { $sum: "$totalQuantity" }
              }
            },
            {
              $project: {
                label: "Autres",
                value: 1,
                _id: 0
              }
            }
          ]
        }
      },
      {
        $project: {
          combined: { $concatArrays: ["$top4", "$others"] }
        }
      },
      { $unwind: "$combined" },
      { $replaceRoot: { newRoot: "$combined" } }
    ]);
    console.log(result);
    res.json({ chartData: result });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};*/

////
async function getCountryData(query) {
  const res = await fetch(`https://restcountries.com/v3.1/name/${query}`);
  const data = await res.json();
  const result = data.map(country => {
    const frenchName = country.name.nativeName?.fra?.common || country.name.common;
    const currencyCode = Object.keys(country.currencies || {})[0];
    const currency = country.currencies?.[currencyCode]?.name || "N/A";
    const symbol = country.currencies?.[currencyCode]?.symbol || "N/A";
    return {
      nom: frenchName,
      devise: currency,
      symbole: symbol,
      codeDevise: currencyCode
    };
  });
  return result;
}


const API_BASE_URL = 'https://v6.exchangerate-api.com/v6';
const API_KEY = process.env.EXCHANGE_RATE_API_KEY;






exports.calculateProjectInvoiceTotal = async (projectIdOrReq, res) => {
  console.log("projecttotal");
  try {
    // Déterminer si la fonction est appelée directement ou via Express
    let projectId;
    let isExpressCall = false;
    
    if (typeof projectIdOrReq === 'string') {
      // Appel direct avec ID de projet
      projectId = projectIdOrReq;
    } else if (projectIdOrReq && projectIdOrReq.params && projectIdOrReq.params.projectId) {
      // Appel via Express
      projectId = projectIdOrReq.params.projectId;
      isExpressCall = true;
    } else {
      const error = new Error('ID de projet non valide');
      if (res) {
        return res.status(400).json({
          success: false,
          message: 'ID de projet non valide'
        });
      }
      throw error;
    }
    
    console.log("Calcul pour le projet ID:", projectId);
    
    // Récupérer le projet avec sa devise
    const project = await Project.findById(projectId);
    if (!project) {
      if (isExpressCall && res) {
        return res.status(404).json({
          success: false,
          message: 'Projet non trouvé'
        });
      }
      throw new Error('Projet non trouvé');
    }
    
    // Devise principale du projet
    const projectCurrency = project.currency || 'USD'; // Valeur par défaut si non définie
    console.log("Devise du projet:", projectCurrency);
    
    // Deuxième devise possible (si définie dans le projet)
    const secondaryCurrency = project.second_currency;
    console.log("Devise secondaire du projet:", secondaryCurrency);
    
    // Récupérer toutes les factures du projet
    const invoices = await Invoice.find({ projectId: projectId });
    console.log("Nombre de factures:", invoices.length);
    
    // Si pas de factures, retourner 0
    if (invoices.length === 0) {
      const resultData = {
        total: 0,
        currency: projectCurrency,
        details: []
      };
      
      // Mettre à jour le projet
      project.totalinvoices = 0;
      await project.save();
      
      if (isExpressCall && res) {
        return res.status(200).json({
          success: true,
          data: resultData
        });
      }
      return resultData;
    }
    
    // Calculer le total en additionnant toutes les factures converties
    let total = 0;
    const details = [];
    
    // On obtient le taux de change entre les deux devises du projet si nécessaire
    let exchangeRate = null;
    if (secondaryCurrency && secondaryCurrency !== projectCurrency) {
      exchangeRate = await getSpecificExchangeRate(projectCurrency, secondaryCurrency);
      console.log(`Taux de change obtenu: 1 ${projectCurrency} = ${exchangeRate} ${secondaryCurrency}`);
    }
    
    for (const invoice of invoices) {
      const invoiceCurrency = invoice.currency || projectCurrency;
      const invoiceAmount = invoice.total || 0;
      
      // Convertir le montant de la facture en devise du projet
      let convertedAmount;
      
      if (invoiceCurrency === projectCurrency) {
        // Pas besoin de conversion si même devise que le projet
        convertedAmount = invoiceAmount;
        console.log(`Facture ${invoice._id}: ${invoiceAmount} ${invoiceCurrency} = ${convertedAmount} ${projectCurrency} (pas de conversion)`);
      } else if (invoiceCurrency === secondaryCurrency && exchangeRate) {
        // Conversion de la devise secondaire à la devise principale
        convertedAmount = invoiceAmount / exchangeRate;
        console.log(`Facture ${invoice._id}: ${invoiceAmount} ${invoiceCurrency} = ${convertedAmount} ${projectCurrency} (avec taux ${exchangeRate})`);
      } else {
        // Devise non reconnue pour ce projet, on utilise l'API pour un taux spécifique
        try {
          const specificRate = await getSpecificExchangeRate(projectCurrency, invoiceCurrency);
          convertedAmount = invoiceAmount / specificRate;
          console.log(`Facture ${invoice._id}: ${invoiceAmount} ${invoiceCurrency} = ${convertedAmount} ${projectCurrency} (avec taux dynamique ${specificRate})`);
        } catch (error) {
          console.error(`Taux de change non disponible pour ${invoiceCurrency}, facture ignorée`);
          continue;
        }
      }
      
      total += convertedAmount;
      console.log("Total cumulé:", total);
      
      details.push({
        invoiceId: invoice._id,
        originalAmount: invoiceAmount,
        originalCurrency: invoiceCurrency,
        convertedAmount: parseFloat(convertedAmount.toFixed(2)),
        convertedCurrency: projectCurrency
      });
    }
    
    // Mettre à jour le total dans le projet
    project.totalinvoices = parseFloat(total.toFixed(2));
    await project.save();
    
    // Préparer les données de résultat
    const resultData = {
      total: parseFloat(total.toFixed(2)),
      currency: projectCurrency,
      details: details,
      updatedAt: new Date()
    };
    
    // Réponse selon le mode d'appel
    if (isExpressCall && res) {
      return res.status(200).json({
        success: true,
        data: resultData
      });
    }
    
    return resultData;
    
  } catch (error) {
    console.error('Erreur lors du calcul du total des factures:', error);
    
    if (res) {
      return res.status(500).json({
        success: false,
        message: 'Erreur lors du calcul du total des factures',
        error: error.message
      });
    }
    
    throw error;  // Propagation de l'erreur si appelé directement
  }
};

/**
 * Obtenir le taux de change spécifique entre deux devises
 * @param {string} fromCurrency - La devise source
 * @param {string} toCurrency - La devise cible
 * @returns {Promise<number>} Le taux de change entre ces deux devises
 * @throws {Error} Si la requête à l'API échoue
 */
const getSpecificExchangeRate = async (fromCurrency, toCurrency) => {
  try {
    const response = await axios.get(`${API_BASE_URL}/${API_KEY}/latest/${fromCurrency}`);
    
    if (response.data.result !== 'success') {
      throw new Error(`Erreur de l'API de taux de change: ${response.data.error || 'Erreur inconnue'}`);
    }
    
    const specificRate = response.data.conversion_rates[toCurrency];
    if (!specificRate) {
      throw new Error(`Taux de change non disponible pour la paire ${fromCurrency}/${toCurrency}`);
    }
    
    return specificRate;
  } catch (error) {
    console.error(`Erreur lors de la récupération du taux de change ${fromCurrency}/${toCurrency}:`, error);
    throw error;
  }
};

/**
 * Obtenir les taux de change pour une devise de base
 * @param {string} baseCurrency - La devise de base pour laquelle obtenir les taux
 * @returns {Promise<Object>} Les données de taux de change
 * @throws {Error} Si la requête à l'API échoue
 */
const getExchangeRates = async (baseCurrency) => {
  try {
    console.log('exchangerate');
    const response = await axios.get(`${API_BASE_URL}/${API_KEY}/latest/${baseCurrency}`);
    
    if (response.data.result !== 'success') {
      throw new Error(`Erreur de l'API de taux de change: ${response.data.error || 'Erreur inconnue'}`);
    }
    
    return response.data;
  } catch (error) {
    console.error('Erreur lors de la récupération des taux de change:', error);
    throw error;
  }
};
// Récupérer les projets consultables par un utilisateur
exports.getViewableProjects = async (req, res) => {
  console.log('viewer');
  console.log(req.user.userId);
  try {
  const projects = await Project.find({
    vupar: { $in: [req.user.userId] }, // 
    status: { $in: [2, 3] }, // statuts actifs ou en alerte
  }).populate('manager', 'name email');

  console.log('projects', projects);
  res.json({ data: projects });
} catch (err) {
  console.error('Erreur lors de la récupération des projets consultables :', err);
  res.status(500).json({ error: 'Erreur serveur' });
}

};
// hethi header ta3 onboarding
exports.fetchiliproject = async (req, res) => {
  console.log("fetchiliprojet");
  try {
    const { projectId } = req.params;
    const userId = req.user.userId ; // Ou récupérez l'user ID comme vous le faites habituellement
    console.log( projectId , userId);
    // Si projectid est fourni, on le prend, sinon on prend le currentProject de l'user
    const targetProjectId =  projectId
      ?  projectId 
      : (await User.findById(userId)).currentProject;

    if (!targetProjectId) {
      return res.status(400).json({ message: "Aucun projet spécifié" });
    }

    const project = await Project.findById(targetProjectId)
    console.log(project);

    if (!project) {
      return res.status(404).json({ message: "Projet non trouvé" });
    }

   

    res.json({
      name: project.name,
      budget: project.budget,
      currency: project.currency,
      totalinvoices:project.totalinvoices || 0,
      //remaining: project.budget - totalinvoices
    });

  } catch (error) {
    console.error("Error in fetchiliproject:", error);
    res.status(500).json({ message: "Erreur serveur" });
  }
};